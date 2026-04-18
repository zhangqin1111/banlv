import os
import time
import unittest
from pathlib import Path
from types import SimpleNamespace
from unittest.mock import patch


TEST_DB_PATH = Path(__file__).resolve().parent / "treehole_test.db"
os.environ["DATABASE_URL"] = f"sqlite:///{TEST_DB_PATH.as_posix()}"

from fastapi.testclient import TestClient  # noqa: E402

from app.db.base import Base  # noqa: E402
from app.db.session import SessionLocal, engine  # noqa: E402
from app.main import app  # noqa: E402
from app.models.ai_budget_event import AIBudgetEvent  # noqa: E402
from app.models.agent_profile import AgentProfile  # noqa: E402
from app.models.home_whisper import HomeWhisper  # noqa: E402
from app.models.treehole import TreeholeSession  # noqa: E402
from app.services.ai_budget_service import consume_ai_budget, get_daily_ai_remaining  # noqa: E402
from app.services.home_service import _build_duo_chat_context  # noqa: E402
from app.services.momo_agent_service import analyze_turn, build_home_agent_context  # noqa: E402


class TreeholeFlowTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls) -> None:
        Base.metadata.drop_all(bind=engine)
        Base.metadata.create_all(bind=engine)
        cls.client = TestClient(app)

    @classmethod
    def tearDownClass(cls) -> None:
        cls.client.close()
        Base.metadata.drop_all(bind=engine)
        engine.dispose()
        if TEST_DB_PATH.exists():
            try:
                TEST_DB_PATH.unlink()
            except PermissionError:
                pass

    def test_treehole_session_messages_and_feedback(self) -> None:
        guest = self.client.post("/v1/auth/guest")
        self.assertEqual(guest.status_code, 200)
        device_id = guest.json()["device_id"]
        headers = {"X-Device-Id": device_id}

        create_session = self.client.post(
            "/v1/treehole/sessions",
            json={"opener": "I feel heavy today."},
            headers=headers,
        )
        self.assertEqual(create_session.status_code, 200)
        session_id = create_session.json()["session_id"]

        with self.client.stream(
            "POST",
            f"/v1/treehole/sessions/{session_id}/stream",
            json={"message": "I feel heavy today."},
            headers=headers,
        ) as response:
            self.assertEqual(response.status_code, 200)
            body = "".join(response.iter_text())
            self.assertIn("event: message_start", body)
            self.assertIn("event: message_done", body)

        messages = self.client.get(
            f"/v1/treehole/sessions/{session_id}/messages",
            headers=headers,
        )
        self.assertEqual(messages.status_code, 200)
        items = messages.json()["items"]
        self.assertGreaterEqual(len(items), 2)
        self.assertEqual(items[0]["role"], "user")

        feedback = self.client.post(
            f"/v1/treehole/sessions/{session_id}/feedback",
            json={"helpful_score": 2},
            headers=headers,
        )
        self.assertEqual(feedback.status_code, 200)
        self.assertEqual(feedback.json()["status"], "saved")

        growth = self.client.get("/v1/growth/summary", headers=headers)
        self.assertEqual(growth.status_code, 200)
        self.assertGreaterEqual(growth.json()["growth_points"], 2)

    def test_treehole_reply_endpoint_returns_full_message(self) -> None:
        guest = self.client.post("/v1/auth/guest")
        device_id = guest.json()["device_id"]
        headers = {"X-Device-Id": device_id}

        create_session = self.client.post(
            "/v1/treehole/sessions",
            json={"opener": "I feel wronged."},
            headers=headers,
        )
        session_id = create_session.json()["session_id"]

        reply = self.client.post(
            f"/v1/treehole/sessions/{session_id}/reply",
            json={"message": "I feel wronged."},
            headers=headers,
        )
        self.assertEqual(reply.status_code, 200)
        data = reply.json()
        self.assertEqual(data["status"], "ok")
        self.assertFalse(data["blocked"])
        self.assertTrue(data["message"])
        self.assertIn(data["suggestion"], {None, "low_mode", "joy_mode", "anger_mode"})

        messages = self.client.get(
            f"/v1/treehole/sessions/{session_id}/messages",
            headers=headers,
        )
        items = messages.json()["items"]
        self.assertGreaterEqual(len(items), 2)
        self.assertEqual(items[-1]["role"], "assistant")

    def test_treehole_safety_block_creates_no_assistant_message(self) -> None:
        guest = self.client.post("/v1/auth/guest")
        device_id = guest.json()["device_id"]
        headers = {"X-Device-Id": device_id}

        create_session = self.client.post(
            "/v1/treehole/sessions",
            json={"opener": "I want to die"},
            headers=headers,
        )
        session_id = create_session.json()["session_id"]

        with self.client.stream(
            "POST",
            f"/v1/treehole/sessions/{session_id}/stream",
            json={"message": "I want to die"},
            headers=headers,
        ) as response:
            body = "".join(response.iter_text())
            self.assertIn("event: safety_block", body)

        messages = self.client.get(
            f"/v1/treehole/sessions/{session_id}/messages",
            headers=headers,
        )
        items = messages.json()["items"]
        self.assertEqual(items, [])

    def test_records_timeline_includes_checkin_mode_and_blind_box(self) -> None:
        guest = self.client.post("/v1/auth/guest")
        device_id = guest.json()["device_id"]
        headers = {"X-Device-Id": device_id}

        checkin = self.client.post(
            "/v1/mood-weather/checkins",
            json={
                "emotion": "低落",
                "intensity": 6,
                "note_text": "Need a little recovery.",
            },
            headers=headers,
        )
        self.assertEqual(checkin.status_code, 200)

        draw = self.client.post(
            "/v1/blind-box/draw",
            json={"worry_text": "Need a little comfort."},
            headers=headers,
        )
        self.assertEqual(draw.status_code, 200)
        draw_id = draw.json()["draw_id"]

        save = self.client.post(f"/v1/blind-box/{draw_id}/save", headers=headers)
        self.assertEqual(save.status_code, 200)
        self.assertTrue(save.json()["is_saved"])

        mode = self.client.post(
            "/v1/modes/sessions",
            json={
                "mode_type": "low_mode",
                "duration_sec": 62,
                "helpful_score": 2,
            },
            headers=headers,
        )
        self.assertEqual(mode.status_code, 200)

        records = self.client.get("/v1/records?days=7", headers=headers)
        self.assertEqual(records.status_code, 200)
        items = records.json()["items"]
        self.assertGreaterEqual(len(items), 3)
        source_types = [item["source_type"] for item in items]
        self.assertIn("mood_weather", source_types)
        self.assertIn("blind_box", source_types)
        self.assertIn("mode", source_types)

    def test_home_summary_uses_most_recent_activity(self) -> None:
        guest = self.client.post("/v1/auth/guest")
        device_id = guest.json()["device_id"]
        headers = {"X-Device-Id": device_id}

        checkin = self.client.post(
            "/v1/mood-weather/checkins",
            json={
                "emotion": "平静",
                "intensity": 4,
                "note_text": "Checking in.",
            },
            headers=headers,
        )
        self.assertEqual(checkin.status_code, 200)

        time.sleep(0.02)
        draw = self.client.post(
            "/v1/blind-box/draw",
            json={"worry_text": "Still moving forward."},
            headers=headers,
        )
        self.assertEqual(draw.status_code, 200)

        summary = self.client.get("/v1/home/summary", headers=headers)
        self.assertEqual(summary.status_code, 200)
        data = summary.json()
        self.assertTrue(data["last_summary"])
        self.assertIn("mood_weather", data["entry_badges"])
        self.assertIn("blind_box", data["entry_badges"])

    def test_mood_weather_returns_invite_cards(self) -> None:
        guest = self.client.post("/v1/auth/guest")
        device_id = guest.json()["device_id"]
        headers = {"X-Device-Id": device_id}

        response = self.client.post(
            "/v1/mood-weather/checkins",
            json={
                "emotion": "生气",
                "intensity": 7,
                "note_text": "Pressure is sitting in my chest.",
            },
            headers=headers,
        )
        self.assertEqual(response.status_code, 200)
        data = response.json()
        self.assertEqual(data["recommended_mode"], "anger_mode")
        self.assertEqual(len(data["invite_cards"]), 3)
        self.assertTrue(all(card["title"] for card in data["invite_cards"]))

    def test_treehole_does_not_force_low_mode_for_generic_hurt(self) -> None:
        guest = self.client.post("/v1/auth/guest")
        device_id = guest.json()["device_id"]
        headers = {"X-Device-Id": device_id}

        create_session = self.client.post(
            "/v1/treehole/sessions",
            json={"opener": "I feel hurt."},
            headers=headers,
        )
        session_id = create_session.json()["session_id"]

        reply = self.client.post(
            f"/v1/treehole/sessions/{session_id}/reply",
            json={"message": "I feel hurt."},
            headers=headers,
        )
        self.assertEqual(reply.status_code, 200)
        self.assertIsNone(reply.json()["suggestion"])

    def test_treehole_companion_mode_changes_agent_strategy_memory(self) -> None:
        guest = self.client.post("/v1/auth/guest")
        device_id = guest.json()["device_id"]
        headers = {"X-Device-Id": device_id}

        create_session = self.client.post(
            "/v1/treehole/sessions",
            json={"opener": "I want help sorting this out."},
            headers=headers,
        )
        session_id = create_session.json()["session_id"]

        reply = self.client.post(
            f"/v1/treehole/sessions/{session_id}/reply",
            json={"message": "Help me sort this out.", "companion_mode": "organize"},
            headers=headers,
        )
        self.assertEqual(reply.status_code, 200)
        self.assertTrue(reply.json()["message"])

        with SessionLocal() as db:
            profile = db.get(AgentProfile, device_id)
            self.assertIsNotNone(profile)
            assert profile is not None
            self.assertEqual(profile.last_strategy, "organize")

    def test_home_summary_returns_dynamic_whisper_lines(self) -> None:
        guest = self.client.post("/v1/auth/guest")
        device_id = guest.json()["device_id"]
        headers = {"X-Device-Id": device_id}

        self.client.post(
            "/v1/mood-weather/checkins",
            json={
                "emotion": "低落",
                "intensity": 6,
                "note_text": "Need some rest.",
            },
            headers=headers,
        )

        summary = self.client.get("/v1/home/summary", headers=headers)
        self.assertEqual(summary.status_code, 200)
        data = summary.json()
        self.assertIn("whisper_lines", data)
        self.assertGreaterEqual(len(data["whisper_lines"]), 3)
        self.assertTrue(all(line.strip() for line in data["whisper_lines"]))
        self.assertEqual(len(data["whisper_lines"]), len(set(data["whisper_lines"])))
        self.assertIn("ai_daily_limit", data)
        self.assertIn("ai_remaining_today", data)
        self.assertGreaterEqual(data["ai_daily_limit"], data["ai_remaining_today"])

    def test_home_summary_returns_duo_chat_lines(self) -> None:
        guest = self.client.post("/v1/auth/guest")
        device_id = guest.json()["device_id"]
        headers = {"X-Device-Id": device_id}

        summary = self.client.get("/v1/home/summary", headers=headers)
        self.assertEqual(summary.status_code, 200)
        data = summary.json()
        self.assertEqual(data["duo_chat_turn_limit"], 4)
        self.assertGreaterEqual(len(data["duo_chat_lines"]), 4)
        self.assertEqual(data["duo_chat_lines"][0]["speaker"], "momo")
        self.assertTrue(all(item["text"].strip() for item in data["duo_chat_lines"]))

    def test_treehole_long_session_compacts_memory_summary(self) -> None:
        guest = self.client.post("/v1/auth/guest")
        device_id = guest.json()["device_id"]
        headers = {"X-Device-Id": device_id}

        create_session = self.client.post(
            "/v1/treehole/sessions",
            json={"opener": "Work and sleep are both stuck."},
            headers=headers,
        )
        session_id = create_session.json()["session_id"]

        for index in range(4):
            reply = self.client.post(
                f"/v1/treehole/sessions/{session_id}/reply",
                json={"message": f"Round {index}: I am still stuck on work, sleep, and exhaustion."},
                headers=headers,
            )
            self.assertEqual(reply.status_code, 200)

        with SessionLocal() as db:
            session = db.get(TreeholeSession, session_id)
            self.assertIsNotNone(session)
            assert session is not None
            self.assertTrue(session.summary_text)
            self.assertLessEqual(len(session.summary_text), 140)

    def test_treehole_can_recall_recent_user_context(self) -> None:
        guest = self.client.post("/v1/auth/guest")
        device_id = guest.json()["device_id"]
        headers = {"X-Device-Id": device_id}

        create_session = self.client.post(
            "/v1/treehole/sessions",
            json={"opener": "A sentence from work is stuck in my head."},
            headers=headers,
        )
        session_id = create_session.json()["session_id"]

        first = self.client.post(
            f"/v1/treehole/sessions/{session_id}/reply",
            json={"message": "I keep replaying that sentence from work."},
            headers=headers,
        )
        self.assertEqual(first.status_code, 200)

        recall = self.client.post(
            f"/v1/treehole/sessions/{session_id}/reply",
            json={"message": "Do you remember what I just said?"},
            headers=headers,
        )
        self.assertEqual(recall.status_code, 200)
        self.assertIn("work", recall.json()["message"].lower())
        self.assertNotIn("don't remember", recall.json()["message"].lower())

    def test_treehole_agent_profile_tracks_memory_and_preference(self) -> None:
        guest = self.client.post("/v1/auth/guest")
        device_id = guest.json()["device_id"]
        headers = {"X-Device-Id": device_id}

        create_session = self.client.post(
            "/v1/treehole/sessions",
            json={"opener": "I feel hurt today, please listen first."},
            headers=headers,
        )
        session_id = create_session.json()["session_id"]

        reply = self.client.post(
            f"/v1/treehole/sessions/{session_id}/reply",
            json={"message": "Please do not solve it yet, just listen to me first."},
            headers=headers,
        )
        self.assertEqual(reply.status_code, 200)

        with SessionLocal() as db:
            profile = db.get(AgentProfile, device_id)
            self.assertIsNotNone(profile)
            assert profile is not None
            self.assertGreaterEqual(profile.turn_count, 1)
            self.assertEqual(profile.support_preference, "listen")
            self.assertTrue(profile.memory_summary)
            self.assertTrue(profile.relationship_note)

    def test_treehole_feedback_updates_agent_helpful_pattern(self) -> None:
        guest = self.client.post("/v1/auth/guest")
        device_id = guest.json()["device_id"]
        headers = {"X-Device-Id": device_id}

        create_session = self.client.post(
            "/v1/treehole/sessions",
            json={"opener": "Help me untangle this mess a little."},
            headers=headers,
        )
        session_id = create_session.json()["session_id"]

        reply = self.client.post(
            f"/v1/treehole/sessions/{session_id}/reply",
            json={"message": "Help me sort these thoughts gently.", "companion_mode": "organize"},
            headers=headers,
        )
        self.assertEqual(reply.status_code, 200)

        feedback = self.client.post(
            f"/v1/treehole/sessions/{session_id}/feedback",
            json={"helpful_score": 2},
            headers=headers,
        )
        self.assertEqual(feedback.status_code, 200)

        with SessionLocal() as db:
            profile = db.get(AgentProfile, device_id)
            self.assertIsNotNone(profile)
            assert profile is not None
            self.assertGreaterEqual(profile.helpful_turn_count, 1)
            self.assertEqual(profile.support_preference, "organize")
            self.assertTrue(profile.helpful_summary)

    def test_treehole_negative_feedback_marks_strategy_to_avoid(self) -> None:
        guest = self.client.post("/v1/auth/guest")
        device_id = guest.json()["device_id"]
        headers = {"X-Device-Id": device_id}

        create_session = self.client.post(
            "/v1/treehole/sessions",
            json={"opener": "Help me sort this out, but the last try felt off."},
            headers=headers,
        )
        session_id = create_session.json()["session_id"]

        reply = self.client.post(
            f"/v1/treehole/sessions/{session_id}/reply",
            json={"message": "Help me think this through.", "companion_mode": "organize"},
            headers=headers,
        )
        self.assertEqual(reply.status_code, 200)

        feedback = self.client.post(
            f"/v1/treehole/sessions/{session_id}/feedback",
            json={"helpful_score": 0},
            headers=headers,
        )
        self.assertEqual(feedback.status_code, 200)

        with SessionLocal() as db:
            profile = db.get(AgentProfile, device_id)
            self.assertIsNotNone(profile)
            assert profile is not None
            self.assertEqual(profile.avoid_strategy, "organize")

    def test_agent_analysis_avoids_recently_rejected_strategy(self) -> None:
        profile = AgentProfile(
            device_id="device-1",
            support_preference="organize",
            avoid_strategy="organize",
            last_strategy="organize",
        )

        plan = analyze_turn(
            profile=profile,
            user_message="Can you help me think this through?",
            history_size=3,
            companion_mode=None,
        )

        self.assertNotEqual(plan.strategy, "organize")
        self.assertEqual(plan.strategy, "listen")

    def test_home_agent_context_includes_avoid_strategy(self) -> None:
        profile = AgentProfile(
            device_id="device-2",
            support_preference="listen",
            avoid_strategy="organize",
            preference_summary="The user prefers gentle listening first.",
            helpful_summary="",
            memory_summary="",
            relationship_note="",
        )

        parts = build_home_agent_context(profile)

        self.assertTrue(any("avoid this style" in part for part in parts))

    def test_home_duo_chat_context_includes_avoid_strategy(self) -> None:
        profile = AgentProfile(
            device_id="device-3",
            support_preference="quiet",
            avoid_strategy="organize",
            relationship_note="The user needs a gentler pace tonight.",
            preference_summary="Less fixing, more quiet company.",
            helpful_summary="Short validating lines landed better.",
        )

        context = _build_duo_chat_context(
            agent_profile=profile,
            latest_summary="The user came back after a hard day.",
            latest_mood=None,
        )

        self.assertIn("organize", context)

    def test_home_whispers_can_follow_agent_preference(self) -> None:
        guest = self.client.post("/v1/auth/guest")
        device_id = guest.json()["device_id"]
        headers = {"X-Device-Id": device_id}

        with SessionLocal() as db:
            db.merge(
                AgentProfile(
                    device_id=device_id,
                    support_preference="quiet",
                    last_strategy="quiet",
                    helpful_turn_count=1,
                    relationship_note="The user currently prefers a quieter pace with momo.",
                    preference_summary="When overwhelmed, the user prefers quiet company over advice.",
                )
            )
            db.commit()

        summary = self.client.get("/v1/home/summary", headers=headers)
        self.assertEqual(summary.status_code, 200)
        self.assertGreaterEqual(len(summary.json()["whisper_lines"]), 3)

        with SessionLocal() as db:
            whisper = db.query(HomeWhisper).filter(HomeWhisper.device_id == device_id).first()
            self.assertIsNotNone(whisper)
            assert whisper is not None
            self.assertIn("quiet", whisper.snapshot_key)

    def test_ai_budget_enforces_daily_limit(self) -> None:
        guest = self.client.post("/v1/auth/guest")
        device_id = guest.json()["device_id"]

        with SessionLocal() as db:
            with patch(
                "app.services.ai_budget_service.settings",
                SimpleNamespace(daily_ai_turn_limit=1),
            ):
                self.assertTrue(
                    consume_ai_budget(
                        db,
                        scope="treehole_reply",
                        device_id=device_id,
                    )
                )
                self.assertFalse(
                    consume_ai_budget(
                        db,
                        scope="home_duo",
                        device_id=device_id,
                    )
                )
                self.assertEqual(get_daily_ai_remaining(db), 0)

    def test_home_summary_falls_back_when_ai_budget_is_blocked(self) -> None:
        guest = self.client.post("/v1/auth/guest")
        device_id = guest.json()["device_id"]
        headers = {"X-Device-Id": device_id}

        fake_qwen = SimpleNamespace(
            is_configured=True,
            complete_chat=lambda **_: (_ for _ in ()).throw(RuntimeError("should not call llm")),
        )

        with patch("app.services.home_service.qwen_client", fake_qwen):
            with patch("app.services.home_service.consume_ai_budget", return_value=False):
                summary = self.client.get("/v1/home/summary", headers=headers)

        self.assertEqual(summary.status_code, 200)
        data = summary.json()
        self.assertGreaterEqual(len(data["whisper_lines"]), 3)
        self.assertGreaterEqual(len(data["duo_chat_lines"]), 4)

    def test_agent_profile_patch_skips_llm_when_budget_is_blocked(self) -> None:
        guest = self.client.post("/v1/auth/guest")
        device_id = guest.json()["device_id"]
        headers = {"X-Device-Id": device_id}
        llm_calls = {"count": 0}

        create_session = self.client.post(
            "/v1/treehole/sessions",
            json={"opener": "I feel a little worn out."},
            headers=headers,
        )
        session_id = create_session.json()["session_id"]

        async def _fail_complete_chat_async(**_: object):
            llm_calls["count"] += 1
            raise RuntimeError("should not call agent llm patch")

        fake_agent_qwen = SimpleNamespace(
            is_configured=True,
            complete_chat_async=_fail_complete_chat_async,
        )

        with patch("app.services.treehole_service.consume_ai_budget", return_value=False):
            with patch("app.services.momo_agent_service.consume_ai_budget", return_value=False):
                with patch("app.services.momo_agent_service.qwen_client", fake_agent_qwen):
                    reply = self.client.post(
                        f"/v1/treehole/sessions/{session_id}/reply",
                        json={"message": "I feel a little worn out."},
                        headers=headers,
                    )

        self.assertEqual(reply.status_code, 200)
        self.assertEqual(llm_calls["count"], 0)

    def test_treehole_reply_falls_back_when_ai_budget_is_blocked(self) -> None:
        guest = self.client.post("/v1/auth/guest")
        device_id = guest.json()["device_id"]
        headers = {"X-Device-Id": device_id}

        create_session = self.client.post(
            "/v1/treehole/sessions",
            json={"opener": "I feel a little worn out."},
            headers=headers,
        )
        session_id = create_session.json()["session_id"]

        fake_qwen = SimpleNamespace(
            is_configured=True,
            stream_chat=lambda **_: (_ for _ in ()).throw(RuntimeError("should not call llm")),
            complete_chat_async=lambda **_: (_ for _ in ()).throw(RuntimeError("should not call llm")),
        )

        with patch("app.services.treehole_service.qwen_client", fake_qwen):
            with patch("app.services.treehole_service.consume_ai_budget", return_value=False):
                reply = self.client.post(
                    f"/v1/treehole/sessions/{session_id}/reply",
                    json={"message": "I feel a little worn out."},
                    headers=headers,
                )

        self.assertEqual(reply.status_code, 200)
        self.assertTrue(reply.json()["message"].strip())

    def test_treehole_stream_falls_back_when_ai_budget_is_blocked(self) -> None:
        guest = self.client.post("/v1/auth/guest")
        device_id = guest.json()["device_id"]
        headers = {"X-Device-Id": device_id}

        create_session = self.client.post(
            "/v1/treehole/sessions",
            json={"opener": "I feel a little quiet tonight."},
            headers=headers,
        )
        session_id = create_session.json()["session_id"]

        async def _fail_stream_chat(**_: object):
            raise RuntimeError("should not call llm")
            yield ""

        async def _fail_complete_chat_async(**_: object):
            raise RuntimeError("should not call llm")

        fake_qwen = SimpleNamespace(
            is_configured=True,
            stream_chat=_fail_stream_chat,
            complete_chat_async=_fail_complete_chat_async,
        )

        with patch("app.services.treehole_service.qwen_client", fake_qwen):
            with patch("app.services.treehole_service.consume_ai_budget", return_value=False):
                with self.client.stream(
                    "POST",
                    f"/v1/treehole/sessions/{session_id}/stream",
                    json={"message": "I feel a little quiet tonight."},
                    headers=headers,
                ) as response:
                    self.assertEqual(response.status_code, 200)
                    body = "".join(response.iter_text())

        self.assertIn("event: message_done", body)
        self.assertIn("event: message_delta", body)

    def test_treehole_session_turn_limit_falls_back_after_cap(self) -> None:
        guest = self.client.post("/v1/auth/guest")
        device_id = guest.json()["device_id"]
        headers = {"X-Device-Id": device_id}
        llm_calls = {"count": 0}

        create_session = self.client.post(
            "/v1/treehole/sessions",
            json={"opener": "I want to keep talking for a while."},
            headers=headers,
        )
        session_id = create_session.json()["session_id"]

        async def _fake_stream_chat(**_: object):
            llm_calls["count"] += 1
            yield "I am here."

        fake_treehole_qwen = SimpleNamespace(
            is_configured=True,
            stream_chat=_fake_stream_chat,
            complete_chat_async=lambda **_: (_ for _ in ()).throw(RuntimeError("should not summarize here")),
        )

        with patch(
            "app.services.treehole_service.get_settings",
            return_value=SimpleNamespace(treehole_session_ai_turn_limit=2),
        ):
            with patch("app.services.treehole_service.consume_ai_budget", return_value=True):
                with patch("app.services.treehole_service.qwen_client", fake_treehole_qwen):
                    with patch("app.services.momo_agent_service.consume_ai_budget", return_value=False):
                        for index in range(3):
                            reply = self.client.post(
                                f"/v1/treehole/sessions/{session_id}/reply",
                                json={"message": f"Round {index} keeps going."},
                                headers=headers,
                            )
                            self.assertEqual(reply.status_code, 200)
                            self.assertTrue(reply.json()["message"].strip())

        self.assertEqual(llm_calls["count"], 2)

    def test_home_summary_reuses_cached_ai_outputs(self) -> None:
        guest = self.client.post("/v1/auth/guest")
        device_id = guest.json()["device_id"]
        headers = {"X-Device-Id": device_id}
        calls = {"count": 0}

        def _fake_complete_chat(*, messages: list[dict[str, str]], **_: object) -> str:
            calls["count"] += 1
            prompt = messages[0]["content"]
            if "双主角" in prompt:
                return json.dumps(
                    [
                        {"speaker": "momo", "text": "今天先把心放轻一点。", "mood": "soft_smile"},
                        {"speaker": "lulu", "text": "嗯，我们陪你慢慢靠岸。", "mood": "cheer"},
                        {"speaker": "momo", "text": "不用一下子说很多。", "mood": "sleepy"},
                        {"speaker": "lulu", "text": "等你想开口时，我们都在。", "mood": "happy"},
                    ],
                    ensure_ascii=False,
                )
            return json.dumps(
                [
                    "今天的你辛苦了。",
                    "黑夜再长，也会有一点星光。",
                    "如果想先安静一下，我就在这里。",
                ],
                ensure_ascii=False,
            )

        fake_qwen = SimpleNamespace(
            is_configured=True,
            complete_chat=_fake_complete_chat,
        )

        with patch("app.services.home_service.qwen_client", fake_qwen):
            with patch("app.services.home_service.consume_ai_budget", return_value=True):
                first = self.client.get("/v1/home/summary", headers=headers)
                second = self.client.get("/v1/home/summary", headers=headers)

        self.assertEqual(first.status_code, 200)
        self.assertEqual(second.status_code, 200)
        self.assertEqual(calls["count"], 2)

    def test_home_summary_cache_preserves_daily_budget(self) -> None:
        guest = self.client.post("/v1/auth/guest")
        device_id = guest.json()["device_id"]
        headers = {"X-Device-Id": device_id}

        call_order = {"count": 0}

        def _fake_complete_chat(*, messages: list[dict[str, str]], **_: object) -> str:
            call_order["count"] += 1
            if call_order["count"] == 1:
                return json.dumps(
                    [
                        "today felt heavy, and you still made it here",
                        "the night can stay dark without swallowing you",
                        "we can pause here for a softer breath",
                    ],
                    ensure_ascii=False,
                )
            return json.dumps(
                [
                    {"speaker": "momo", "text": "let's take this gently tonight", "mood": "soft_smile"},
                    {"speaker": "lulu", "text": "we can stay here with you", "mood": "cheer"},
                    {"speaker": "momo", "text": "you do not have to explain it all", "mood": "sleepy"},
                    {"speaker": "lulu", "text": "we will keep a warm light on", "mood": "happy"},
                ],
                ensure_ascii=False,
            )

        fake_qwen = SimpleNamespace(
            is_configured=True,
            complete_chat=_fake_complete_chat,
        )

        with SessionLocal() as db:
            with patch(
                "app.services.ai_budget_service.settings",
                SimpleNamespace(daily_ai_turn_limit=50),
            ):
                before_count = (
                    db.query(AIBudgetEvent)
                    .filter(AIBudgetEvent.device_id == device_id)
                    .count()
                )
                with patch("app.services.home_service.qwen_client", fake_qwen):
                    first = self.client.get("/v1/home/summary", headers=headers)
                    after_first_count = (
                        db.query(AIBudgetEvent)
                        .filter(AIBudgetEvent.device_id == device_id)
                        .count()
                    )
                    second = self.client.get("/v1/home/summary", headers=headers)
                    after_second_count = (
                        db.query(AIBudgetEvent)
                        .filter(AIBudgetEvent.device_id == device_id)
                        .count()
                    )

        self.assertEqual(first.status_code, 200)
        self.assertEqual(second.status_code, 200)
        self.assertEqual(after_first_count - before_count, 2)
        self.assertEqual(after_second_count, after_first_count)


if __name__ == "__main__":
    unittest.main()
