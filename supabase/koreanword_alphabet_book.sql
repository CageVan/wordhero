-- 在云端共用词库(koreanword_lib) 追加/更新「韩语字母」书（40 字母）。
-- 幂等：master 行不存在则插入；已有「韩语字母」书则整本替换；否则追加。
-- 运行：Supabase 后台 SQL Editor 粘贴执行（需先运行 koreanword_tables.sql 建表）。
do $$
declare
  b jsonb := jsonb_build_object(
    'name','韩语字母',
    'words', jsonb_build_array(
      jsonb_build_object('t',$$ㄱ$$,'p',$$giyeok$$::text,'d',$$辅音 ㄱ，发音近似 g（词首轻、不送气）$$::text,'ex',$$가$$::text,'exCn',$$家 / 去（ga）$$::text),
      jsonb_build_object('t',$$ㄴ$$,'p',$$nieun$$::text,'d',$$辅音 ㄴ，发音 n$$::text,'ex',$$나$$::text,'exCn',$$我（na）$$::text),
      jsonb_build_object('t',$$ㄷ$$,'p',$$digeut$$::text,'d',$$辅音 ㄷ，发音近似 d（不送气）$$::text,'ex',$$다$$::text,'exCn',$$题 / 给（da）$$::text),
      jsonb_build_object('t',$$ㄹ$$,'p',$$rieul$$::text,'d',$$辅音 ㄹ，发音 r/l（颤音或边音）$$::text,'ex',$$라$$::text,'exCn',$$乐 / 来（ra）$$::text),
      jsonb_build_object('t',$$ㅁ$$,'p',$$mieum$$::text,'d',$$辅音 ㅁ，发音 m$$::text,'ex',$$마$$::text,'exCn',$$马（ma）$$::text),
      jsonb_build_object('t',$$ㅂ$$,'p',$$bieup$$::text,'d',$$辅音 ㅂ，发音 b（不送气）$$::text,'ex',$$바$$::text,'exCn',$$梨 / 船（ba）$$::text),
      jsonb_build_object('t',$$ㅅ$$,'p',$$siot$$::text,'d',$$辅音 ㅅ，发音 s$$::text,'ex',$$사$$::text,'exCn',$$事 / 四（sa）$$::text),
      jsonb_build_object('t',$$ㅇ$$,'p',$$ieung$$::text,'d',$$辅音 ㅇ：作初声不发音；作终声发 ng$$::text,'ex',$$아$$::text,'exCn',$$牙（a）$$::text),
      jsonb_build_object('t',$$ㅈ$$,'p',$$jieut$$::text,'d',$$辅音 ㅈ，发音 j（不送气）$$::text,'ex',$$자$$::text,'exCn',$$子（ja）$$::text),
      jsonb_build_object('t',$$ㅊ$$,'p',$$chieut$$::text,'d',$$辅音 ㅊ，发音 ch（送气）$$::text,'ex',$$차$$::text,'exCn',$$茶（cha）$$::text),
      jsonb_build_object('t',$$ㅋ$$,'p',$$kieuk$$::text,'d',$$辅音 ㅋ，发音 k（送气）$$::text,'ex',$$카$$::text,'exCn',$$卡（ka）$$::text),
      jsonb_build_object('t',$$ㅌ$$,'p',$$tieut$$::text,'d',$$辅音 ㅌ，发音 t（送气）$$::text,'ex',$$타$$::text,'exCn',$$他（ta）$$::text),
      jsonb_build_object('t',$$ㅍ$$,'p',$$pieup$$::text,'d',$$辅音 ㅍ，发音 p（送气）$$::text,'ex',$$파$$::text,'exCn',$$葱 / 坡（pa）$$::text),
      jsonb_build_object('t',$$ㅎ$$,'p',$$hieut$$::text,'d',$$辅音 ㅎ，发音 h$$::text,'ex',$$하$$::text,'exCn',$$河 / 下（ha）$$::text),
      jsonb_build_object('t',$$ㄲ$$,'p',$$ssanggiyeok$$::text,'d',$$紧音 ㄲ，发音 gɡ（用力、不送气）$$::text,'ex',$$까$$::text,'exCn',$$硬 / 岁月（kka）$$::text),
      jsonb_build_object('t',$$ㄸ$$,'p',$$ssangdigeut$$::text,'d',$$紧音 ㄸ，发音 dd$$::text,'ex',$$따$$::text,'exCn',$$地方 / 打（tta）$$::text),
      jsonb_build_object('t',$$ㅃ$$,'p',$$ssangbieup$$::text,'d',$$紧音 ㅃ，发音 bb$$::text,'ex',$$빠$$::text,'exCn',$$快（ppa）$$::text),
      jsonb_build_object('t',$$ㅆ$$,'p',$$ssangsiot$$::text,'d',$$紧音 ㅆ，发音 ss$$::text,'ex',$$싸$$::text,'exCn',$$便宜（ssa）$$::text),
      jsonb_build_object('t',$$ㅉ$$,'p',$$ssangjieut$$::text,'d',$$紧音 ㅉ，发音 jj$$::text,'ex',$$짜$$::text,'exCn',$$稠 / 咸（jja）$$::text),
      jsonb_build_object('t',$$ㅏ$$,'p',$$a$$::text,'d',$$单元音 ㅏ，发音 a$$::text,'ex',$$아$$::text,'exCn',$$牙（a）$$::text),
      jsonb_build_object('t',$$ㅑ$$,'p',$$ya$$::text,'d',$$元音 ㅑ，发音 ya$$::text,'ex',$$야$$::text,'exCn',$$孩子 / 也（ya）$$::text),
      jsonb_build_object('t',$$ㅓ$$,'p',$$eo$$::text,'d',$$单元音 ㅓ，发音 eo（似 o，介于 e-o 之间）$$::text,'ex',$$어$$::text,'exCn',$$语 / 鱼（eo）$$::text),
      jsonb_build_object('t',$$ㅕ$$,'p',$$yeo$$::text,'d',$$元音 ㅕ，发音 yeo$$::text,'ex',$$여$$::text,'exCn',$$女 / 旅（yeo）$$::text),
      jsonb_build_object('t',$$ㅗ$$,'p',$$o$$::text,'d',$$单元音 ㅗ，发音 o$$::text,'ex',$$오$$::text,'exCn',$$五 / 哦（o）$$::text),
      jsonb_build_object('t',$$ㅛ$$,'p',$$yo$$::text,'d',$$元音 ㅛ，发音 yo$$::text,'ex',$$요$$::text,'exCn',$$要 / 腰（yo）$$::text),
      jsonb_build_object('t',$$ㅜ$$,'p',$$u$$::text,'d',$$单元音 ㅜ，发音 u$$::text,'ex',$$우$$::text,'exCn',$$雨 / 右（u）$$::text),
      jsonb_build_object('t',$$ㅠ$$,'p',$$yu$$::text,'d',$$元音 ㅠ，发音 yu$$::text,'ex',$$유$$::text,'exCn',$$邮 / 有（yu）$$::text),
      jsonb_build_object('t',$$ㅡ$$,'p',$$eu$$::text,'d',$$单元音 ㅡ，发音 eu（轻“呃”）$$::text,'ex',$$으$$::text,'exCn',$$表示“的”音（eu）$$::text),
      jsonb_build_object('t',$$ㅣ$$,'p',$$i$$::text,'d',$$单元音 ㅣ，发音 i$$::text,'ex',$$이$$::text,'exCn',$$二 / 牙（i）$$::text),
      jsonb_build_object('t',$$ㅐ$$,'p',$$ae$$::text,'d',$$复合元音 ㅐ，发音 ae$$::text,'ex',$$애$$::text,'exCn',$$唉（ae）$$::text),
      jsonb_build_object('t',$$ㅒ$$,'p',$$yae$$::text,'d',$$复合元音 ㅒ，发音 yae$$::text,'ex',$$얘$$::text,'exCn',$$孩子 / 얘기（yae）$$::text),
      jsonb_build_object('t',$$ㅔ$$,'p',$$e$$::text,'d',$$复合元音 ㅔ，发音 e$$::text,'ex',$$에$$::text,'exCn',$$哎 / 位置（e）$$::text),
      jsonb_build_object('t',$$ㅖ$$,'p',$$ye$$::text,'d',$$复合元音 ㅖ，发音 ye$$::text,'ex',$$예$$::text,'exCn',$$礼 / 例（ye）$$::text),
      jsonb_build_object('t',$$ㅘ$$,'p',$$wa$$::text,'d',$$复合元音 ㅘ，发音 wa$$::text,'ex',$$와$$::text,'exCn',$$和 / 瓦（wa）$$::text),
      jsonb_build_object('t',$$ㅙ$$,'p',$$wae$$::text,'d',$$复合元音 ㅙ，发音 wae$$::text,'ex',$$왜$$::text,'exCn',$$为什么 / 歪（wae）$$::text),
      jsonb_build_object('t',$$ㅚ$$,'p',$$oe$$::text,'d',$$复合元音 ㅚ，发音 oe$$::text,'ex',$$외$$::text,'exCn',$$外 / 胃（oe）$$::text),
      jsonb_build_object('t',$$ㅝ$$,'p',$$wo$$::text,'d',$$复合元音 ㅝ，发音 wo$$::text,'ex',$$워$$::text,'exCn',$$越 / 워（wo）$$::text),
      jsonb_build_object('t',$$ㅞ$$,'p',$$we$$::text,'d',$$复合元音 ㅞ，发音 we$$::text,'ex',$$웨$$::text,'exCn',$$威 / 喂（we）$$::text),
      jsonb_build_object('t',$$ㅟ$$,'p',$$wi$$::text,'d',$$复合元音 ㅟ，发音 wi$$::text,'ex',$$위$$::text,'exCn',$$胃 / 位（wi）$$::text),
      jsonb_build_object('t',$$ㅢ$$,'p',$$ui$$::text,'d',$$复合元音 ㅢ，发音 ui$$::text,'ex',$$의$$::text,'exCn',$$的 / 衣（ui）$$::text)
    )
  );
  has_master boolean;
  has_book boolean;
begin
  select exists(select 1 from koreanword_lib where id='master') into has_master;
  select exists(select 1 from koreanword_lib where id='master' and books @> '[{"name":"韩语字母"}]') into has_book;
  if not has_master then
    insert into koreanword_lib (id, books, updated_at) values ('master', jsonb_build_array(b), now());
  elsif has_book then
    update koreanword_lib set books = (
      select jsonb_agg(case when (x->>'name')='韩语字母' then b else x end)
      from jsonb_array_elements(books) x
    ), updated_at=now() where id='master';
  else
    update koreanword_lib set books = books || jsonb_build_array(b), updated_at=now() where id='master';
  end if;
end $$;
