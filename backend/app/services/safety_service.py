from dataclasses import dataclass


HIGH_RISK_RULES = {
    "想死": "self_harm_keyword",
    "自杀": "self_harm_keyword",
    "不想活": "self_harm_keyword",
    "结束自己": "self_harm_keyword",
    "活不下去": "self_harm_keyword",
    "i want to die": "self_harm_keyword",
    "want to die": "self_harm_keyword",
    "kill myself": "self_harm_keyword",
    "suicide": "self_harm_keyword",
    "end my life": "self_harm_keyword",
    "hurt myself": "self_harm_keyword",
    "伤害别人": "harm_others_keyword",
    "杀了他": "harm_others_keyword",
    "kill him": "harm_others_keyword",
    "kill her": "harm_others_keyword",
    "kill them": "harm_others_keyword",
    "hurt someone": "harm_others_keyword",
}


@dataclass(frozen=True)
class SafetyDecision:
    blocked: bool
    reason: str = ""
    severity: str = "low"


def detect_high_risk(text: str) -> SafetyDecision:
    normalized = text.strip().lower()
    for keyword, reason in HIGH_RISK_RULES.items():
        if keyword in normalized:
            return SafetyDecision(blocked=True, reason=reason, severity="critical")
    return SafetyDecision(blocked=False)
