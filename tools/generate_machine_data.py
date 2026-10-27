#!/usr/bin/env python3
"""Authoring utility for the three original Reelworks Arcade machine modules."""
import json
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
base_strips = [
 ['cherry','lemon','bell','cherry','bar','lemon','seven','cherry','lemon','special','bell','bar','cherry','lemon','bell','seven','cherry','bar','lemon','cherry','bell','special','lemon','bar','cherry','seven','lemon','bell','bar','cherry'],
 ['lemon','cherry','bar','bell','cherry','seven','lemon','bar','cherry','bell','lemon','special','cherry','bar','lemon','seven','bell','cherry','lemon','bar','cherry','bell','special','lemon','seven','cherry','bar','bell','cherry','lemon'],
 ['bell','cherry','lemon','bar','seven','cherry','lemon','bell','cherry','bar','special','lemon','cherry','seven','bar','lemon','bell','cherry','lemon','bar','bell','cherry','seven','lemon','special','bar','cherry','bell','lemon','cherry'],
]

def square(label, kind, value):
 return {'label':label,'kind':kind,'value':value}
def feature(label, ident): return square(label,'feature',ident)

configs = [
 {
  'id':'last_orders','name':'LAST ORDERS','subtitle':'One more for the road? Make it fictional.','description':'Brass bells, cheeky barrels and a winding crawl through the cosiest pub in the arcade.',
  'jackpot':500,'stake':10,'colors':{'bg':'112c24','primary':'d58027','secondary':'234d36','accent':'ffdc79'},
  'special_label':'Lucky Bell','trail_name':'PUB CRAWL','trail_length':24,'board_layout':'winding','feature_title':'PUB CRAWL TRAIL',
  'special_feature':'lucky_bells',
  'features':['darts_dash','mystery_barrel','super_hold','cash_climb','last_call_streak','lucky_bells','cash_repeater','win_spin','extra_life','no_lose','add_again','cash_pot','feature_shot','feature_upgrade','reel_skill','super_nudges','lucky_seven','bonus_selector','mystery_bonus','streak_feature'],
  'trail':[
   square('OPEN','cash',10),square('20','cash',20),square('NUDGE','nudges',2),feature('DARTS','darts_dash'),square('?','mystery',0),square('40','cash',40),
   square('LIFE','life',1),feature('BARREL','mystery_barrel'),square('60','cash',60),feature('HOLD','super_hold'),square('UPGRADE','upgrade',1),feature('LADDER','cash_climb'),
   square('80','cash',80),feature('REPEAT','cash_repeater'),square('NUDGE','nudges',3),feature('SHOT','feature_shot'),square('?','mystery',0),square('100','cash',100),
   feature('BELLS','lucky_bells'),square('AGAIN','repeat',1),feature('NO LOSE','no_lose'),square('150','cash',150),feature('POT','cash_pot'),feature('LAST CALL','last_call_streak')
  ],
  'rules':[
   '18+ free-play simulation. All amounts are fictional credits with no monetary or transferable value. Each START costs 10 credits; refill is always free.',
   'Only three matching symbols on the centre winline pay the printed triple prize. Each unheld reel independently selects one of its 30 physical stops with equal probability.',
   'Centre-symbol number overlays add to the Pub Crawl meter. Every complete 24 steps opens a six-turn Pub Crawl feature. A triple Lucky Bell also opens its bonus selector.',
   'Offered HOLD buttons keep their exact reel stops for the next paid spin. NUDGE UP and DOWN move one real strip stop and consume one nudge.',
   'Darts Dash: 12 visible lamp positions advance every 100 ms. STOP locks the displayed position: lamps 6 or 7 pay 120; lamps 5 or 8 pay 60; the other lamps pay 20. Reduced motion freezes the indicator and uses the same award table.',
   'Mystery Barrel: choose one of three covered barrels; the chosen award is drawn uniformly when selected and saved immediately. Each barrel has the same published distribution.',
   'Cash Ladder uses uniform independent numbers 1 to 12. HI or LO wins only on a strict higher or lower result; equal numbers lose unless protected. COLLECT banks the current pot; EXCHANGE uses the displayed fixed alternative.',
   'Last Call Streak contains three to six independent prize reveals. Press CONTINUE to reveal each prize and then COLLECT. No time pressure applies.',
   'The board uses original, independent random events. There is no compensated payout, near-miss manipulation, advertised RTP, purchase, withdrawal or online connection.'
  ],
 },
 {
  'id':'empire_estates','name':'EMPIRE ESTATES','subtitle':'Raise the skyline. Rule your own district.','description':'Choose a district, collect construction plans and build a miniature city of illuminated prizes.',
  'jackpot':750,'stake':10,'colors':{'bg':'0d2035','primary':'237c5b','secondary':'102f4a','accent':'ecd391'},
  'special_label':'Construction','trail_name':'DISTRICT CIRCUIT','trail_length':20,'board_layout':'districts','feature_title':'DISTRICT CIRCUIT',
  'special_feature':'property_pick','districts':['Canal Quarter','Foundry Row','Lantern Heights'],
  'features':['property_pick','auction_offer','building_bonus','rent_rush','tycoon_trail','empire_streak','bonus_exchange','cash_pot','cash_climb','feature_upgrade','win_spin','super_hold','cash_repeater','bonus_selector','extra_life','feature_shot','add_again','no_lose'],
  'trail':[
   square('GATE','cash',15),feature('PICK','property_pick'),square('25','cash',25),feature('BUILD','building_bonus'),square('NUDGE','nudges',2),
   feature('AUCTION','auction_offer'),square('50','cash',50),square('LIFE','life',1),feature('RENT','rent_rush'),square('UPGRADE','upgrade',1),
   feature('TYCOON','tycoon_trail'),square('75','cash',75),feature('PICK','property_pick'),square('?','mystery',0),feature('EXCHANGE','bonus_exchange'),
   square('125','cash',125),feature('BUILD','building_bonus'),square('AGAIN','repeat',1),feature('POT','cash_pot'),feature('EMPIRE','empire_streak')
  ],
  'rules':[
   '18+ free-play simulation. All amounts are fictional credits with no monetary or transferable value. Each START costs 10 credits; refill is always free.',
   'Only three matching symbols on the centre winline pay the printed triple prize. Each unheld reel independently selects one of its 30 stops with equal probability.',
   'Centre-symbol number overlays fill the 20-step District Circuit meter. A complete circuit opens six board turns. Three Construction symbols open Property Pick.',
   'At a District Circuit route choice, choose Canal Quarter, Foundry Row or Lantern Heights. The chosen route changes the board destination and tracks district progress across visits.',
   'Property Pick: select one of three equally distributed cards to receive an award or modifier. Construction progress upgrades feature prizes; Rent Rush reveals awards from the unlocked district buildings.',
   'Auction Offer starts at 40. COLLECT accepts the current offer. Each CONTINUE has a 2/3 chance of adding 40 and a 1/3 chance of losing the offer. Four successful raises finish the auction.',
   'Tycoon Trail uses independent uniform numbers 1 to 12. A correct strict HI or LO prediction advances the ladder. Equal numbers count as losses unless protected.',
   'Bonus Exchange moves the current board pot into a Cash Ladder, with a minimum starting value of 40. That board pot is removed before the ladder opens. In any ladder, EXCHANGE ends the ladder for half its current pot, rounded down.',
   'HOLD preserves exact stops when offered; NUDGE moves one stop. Empire Streak reveals its sequence once. Rules and credits are saved after accepted actions.',
   'The board uses original, independent random events. There is no compensated payout, near-miss manipulation, advertised RTP, purchase, withdrawal or online connection.'
  ],
 },
 {
  'id':'time_shift','name':'TIME SHIFT','subtitle':'The future is only one stop away.','description':'Charge the coils, rewind the reels and jump between three eras on a looping time circuit.',
  'jackpot':1000,'stake':10,'colors':{'bg':'171a38','primary':'8545b7','secondary':'1c3d65','accent':'64e7ec'},
  'special_label':'Clock','trail_name':'TIME CIRCUIT','trail_length':24,'board_layout':'orbit','feature_title':'TIME CIRCUIT',
  'special_feature':'time_jump','zones':['Past','Present','Future'],
  'features':['temporal_hi_lo','rewind','time_jump','temporal_surge','super_shift','paradox_mystery','cash_climb','super_nudges','feature_upgrade','no_lose','extra_life','lucky_seven','reel_skill','feature_shot','bonus_selector','cash_repeater'],
  'trail':[
   square('PAST','cash',15),feature('REWIND','rewind'),square('30','cash',30),square('LIFE','life',1),feature('CLOCK','temporal_hi_lo'),square('NUDGE','nudges',2),feature('PARADOX','paradox_mystery'),feature('JUMP','time_jump'),
   square('NOW','cash',50),feature('SHIFT','super_shift'),square('75','cash',75),square('UPGRADE','upgrade',1),feature('CLOCK','temporal_hi_lo'),feature('SKILL','reel_skill'),square('?','mystery',0),feature('JUMP','time_jump'),
   square('FUTURE','cash',100),feature('SURGE','temporal_surge'),square('NUDGE','nudges',4),feature('NO LOSE','no_lose'),square('150','cash',150),feature('PARADOX','paradox_mystery'),square('AGAIN','repeat',1),feature('SURGE','temporal_surge')
  ],
  'rules':[
   '18+ free-play simulation. All amounts are fictional credits with no monetary or transferable value. Each START costs 10 credits; refill is always free.',
   'Only three matching symbols on the centre winline pay the printed triple prize. Each unheld reel independently selects one of its 30 stops with equal probability.',
   'Centre-symbol number overlays charge a 24-step looping Time Circuit. Completing the meter opens six board turns. Three Clock symbols activate the Time Jump feature.',
   'Positions 1–8 are Past, 9–16 Present, and 17–24 Future. Time Jump offers an explicit era choice and moves to the chosen zone. Each era contains its own printed feature positions.',
   'Temporal Hi-Lo draws independent uniform numbers 1 to 12. HI and LO must be strictly correct; equality loses unless protected. COLLECT banks the current fictional award.',
   'An earned Rewind restores defined previous reel positions. It is limited to the earned charge and may not repeatedly evaluate the same award. Super Shift grants enhanced nudges and a feature upgrade.',
   'Temporal Surge reveals an escalating sequence of independently chosen awards. CONTINUE reveals the next award; COLLECT is offered on completion.',
   'Paradox Mystery draws uniformly from four outcomes: Rewind plus 20, Time Jump, Super Shift, or 160 credits. No clock time or animation changes a random award.',
   'HOLD preserves exact stops when offered; NUDGE moves one stop. STOP features use the visible 12-position indicator, not hidden random timing.',
   'The board uses original, independent random events. There is no compensated payout, near-miss manipulation, advertised RTP, purchase, withdrawal or online connection.'
  ],
 }
]

for idx,c in enumerate(configs):
 c.update({'schema_version':1,'board_turns':6,'hold_chance':[1,4],'nudge_chance':[1,5],'special_symbol':'special','artwork':f"res://assets/cabinets/{c['id']}.svg"})
 prize_rows = [[20,30,60,100,200,500],[25,40,75,150,250,750],[15,35,80,120,300,1000]]
 prizes = dict(zip(['cherry','lemon','bell','bar','seven','special'],prize_rows[idx]))
 labels = {'cherry':'Cherries','lemon':'Lemon','bell':'Brass Bell','bar':'BAR','seven':'Red Seven','special':c.pop('special_label')}
 nums = {'cherry':0,'lemon':1,'bell':2,'bar':0,'seven':3,'special':0}
 c['symbols'] = {ident:{'label':labels[ident],'prize':prizes[ident],'number':nums[ident],'icon':f"res://assets/symbols/{c['id']+'_special' if ident=='special' else ident}.svg"} for ident in labels}
 c['rules'].extend([
  'TRIPLE PAYTABLE: ' + '; '.join(f'{labels[k]} {v}' for k,v in prizes.items()) + ' fictional credits. All other centre combinations pay zero. Row above and row below are preview stops, not additional paylines.',
  'OVERPRINTS: Lemon 1; Brass Bell 2; Red Seven 3; Cherries, BAR and themed symbol 0. Sum the three centre numbers after a paid spin. Nudge movement does not add more trail numbers.',
  'On a non-winning spin without a feature entry, HOLD is offered with probability 1/4. If no HOLD is offered, NUDGE is offered with probability 1/5 (3/20 overall), with 1, 2 or 3 nudges equally likely.',
  'Board movement rolls 1 to 6 uniformly. Cash squares add their printed value to the pot; LIFE grants one hi-lo protection; UPGRADE raises the board multiplier by one up to x4; AGAIN adds one board turn, capped at 12. Bonuses return their awards to the board pot.',
  'Mystery squares select uniformly from this cabinet’s feature list. Each random draw is independent. The currently lit square and prompt describe the resulting playable feature.',
  'Cash Ladder begins at at least 20. A successful strict HI/LO prediction doubles the pot up to the decorative jackpot; six successes also finish the ladder. Equal numbers lose. An earned No Lose or Extra Life absorbs one losing result. COLLECT keeps all; EXCHANGE keeps half, rounded down.',
  'Reel Skill stops reel 3 at the displayed lamp index and pays its skill award plus any centre-line triple. Feature Shot lamps 6/7 open a streak, 5/8 pay 40, others 10. No paid-spin outcome is altered by these bonus rules.',
  'Win Spin selects uniformly among the six payable symbols and sets an explicit winning triple. Super Hold offers three free spins preserving selected reels, ends on the first match, then grants two further HOLD offers. Super Nudges gives six real strip steps; the first match ends the bonus.',
  'Cash Pot chooses one of 20,30,40,50,60,70,80,90,100 uniformly. Lucky Seven draws 1 to 12 uniformly: 7 pays 200, all others 20. Mystery Barrel and Mystery Bonus choose 20,40,80,120 with equal probability for every cover.',
  'Cash Repeater starts at 40. CONTINUE has a 1/2 chance to add 40; failure ends the bonus and keeps the pot. At most five successful repeats. Add Again adds the current board pot once (minimum 20). Extra Life and No Lose also add 20.',
  'Streaks choose 3, 4, 5 or 6 reveals uniformly. Reveal n pays n times one of 10, 20, 30, drawn uniformly. Feature Upgrade raises the board multiplier by one to a maximum x4. Board cash and returned bonus awards use the current multiplier.',
  'Lucky Bells and Bonus Selector explicitly offer Reel Skill, Cash Climb or Cash Pot. They are player choices, not secretly weighted random results.'
 ])
 c['paytable']=prizes
 c['strips']=[row[(idx*3+i)%len(row):]+row[:(idx*3+i)%len(row)] for i,row in enumerate(base_strips)]
 if idx==1:
  # Two additional construction stops replace lemons, making the city strips distinct.
  c['strips'][0][5]='special'; c['strips'][1][0]='bar'; c['strips'][2][14]='special'
 if idx==2:
  # Time Shift has a different distribution of clock and seven overprints.
  c['strips'][0][9]='seven'; c['strips'][1][20]='special'; c['strips'][2][2]='bell'
 (ROOT/'data/machines'/f"{c['id']}.json").write_text(json.dumps(c,indent=2)+'\n')
 print(c['id'],len(c['trail']),[len(x) for x in c['strips']])
