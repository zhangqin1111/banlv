from random import choice
from uuid import uuid4

from sqlalchemy import select
from sqlalchemy.orm import Session

from app.models.blind_box_draw import BlindBoxDraw
from app.schemas.blind_box import BlindBoxDrawRequest, BlindBoxDrawResponse
from app.services.growth_service import award_growth

CARD_LIBRARY = {
    "comfort": [
        (
            "先把肩膀放松一点",
            "现在不用解决一整天，只先照顾这一分钟。你已经撑了很久，先把力气往自己这边收一点。",
        ),
        (
            "可以先慢一小步",
            "你不需要马上变好。先把呼吸放回身体里一点，也算在往前。",
        ),
        (
            "今天先允许自己软一点",
            "累的时候不用还维持很完整，先让自己靠一靠，也是一种照顾。",
        ),
        (
            "先替现在的你留个位置",
            "不是所有难受都要立刻清掉。先让自己被放在一个更柔软的地方，也很好。",
        ),
    ],
    "action": [
        (
            "让今天短一点",
            "把下一步缩小到一口水、一步路、一次深呼吸，也已经很够了。",
        ),
        (
            "只拿最轻的一件事",
            "不用急着把清单做完，先挑一件最轻的放到手边。",
        ),
        (
            "先帮自己收一根线头",
            "如果脑子里太乱，就只整理最先冒出来的那一件，别同时扛全部。",
        ),
        (
            "给这一刻一个小动作",
            "站起来、伸展一下、去窗边看一眼光，都能让这阵卡住感松一点。",
        ),
    ],
    "reframe": [
        (
            "先和自己站在一起",
            "你现在需要的也许不是更努力，而是先别继续责怪自己。",
        ),
        (
            "今天不用表现得很完整",
            "允许自己有点乱、有点慢，不会让你变得更糟。",
        ),
        (
            "不是你不够好，是今天太满了",
            "有时候难受不是因为你差，而是已经被很多东西同时拉扯太久了。",
        ),
        (
            "把标准先放低一点",
            "这一刻不需要做到最好，只需要先让自己没那么难受。",
        ),
    ],
}


def _select_card_bucket(worry_text: str) -> str:
    normalized = worry_text.strip()
    if not normalized:
        return choice(list(CARD_LIBRARY.keys()))

    if any(keyword in normalized for keyword in ("累", "疲惫", "撑不住", "困", "烦", "没电")):
        return "comfort"
    if any(
        keyword in normalized
        for keyword in ("做不完", "来不及", "拖延", "不知道从哪开始", "好乱", "卡住")
    ):
        return "action"
    if any(
        keyword in normalized
        for keyword in ("是不是我不够好", "内疚", "责怪自己", "失望", "没用")
    ):
        return "reframe"
    return choice(list(CARD_LIBRARY.keys()))


def draw_card(
    db: Session,
    *,
    device_id: str,
    payload: BlindBoxDrawRequest,
) -> BlindBoxDrawResponse:
    card_type = _select_card_bucket(payload.worry_text)
    title, body = choice(CARD_LIBRARY[card_type])
    draw = BlindBoxDraw(
        device_id=device_id,
        mood_entry_id=payload.mood_entry_id,
        worry_text_redacted=payload.worry_text[:120],
        card_type=card_type,
        card_title=title,
        card_body=body,
    )
    db.add(draw)
    db.commit()
    db.refresh(draw)
    award_growth(
        db,
        device_id=device_id,
        source_type="blind_box",
        source_id=draw.id,
    )
    return BlindBoxDrawResponse(
        draw_id=draw.id or str(uuid4()),
        card_type=card_type,
        card_title=title,
        card_body=body,
    )


def save_draw(db: Session, *, device_id: str, draw_id: str) -> bool:
    draw = db.scalar(
        select(BlindBoxDraw).where(
            BlindBoxDraw.id == draw_id,
            BlindBoxDraw.device_id == device_id,
        )
    )
    if draw is None:
        return False

    draw.is_saved = True
    db.commit()
    return True
