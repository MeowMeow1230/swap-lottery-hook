# Demo 影片腳本（~2 分鐘，嚴格對應 PPT 頁數）

---

## Slide 1｜封面（0:00-0:10）
**畫面**：PPT Slide 1 — "Swap Lottery Hook — Make Every Swap a Winning Ticket"
**口白**：
"Swap Lottery Hook — turning every Uniswap V4 swap into a lottery ticket. Built for Hook the Future on X Layer."

---

## Slide 2｜問題（0:10-0:22）
**畫面**：PPT Slide 2 — "Why Existing Solutions Don't Work"
**口白**：
"Traders flow through pools like water — swap once, never return. Static fees give them no reason to come back. Points programs delay gratification for months. And existing dynamic fee hooks protect LPs but drive traders away. We need a mechanism that rewards both sides."

---

## Slide 3｜核心機制（0:22-0:38）
**畫面**：PPT Slide 3 — "Core Mechanism: The Lottery Flywheel"
**口白**：
"Here's the solution. 0.01 percent invisible tax on every swap output. Dynamic-N curve: when the prize pool is small, N is low — quick wins build hope. When it grows large, N rises — anticipation builds. Always bounded between 100 and 200. Then multi-tier prizes: 60 percent grand prize, ten consolation winners at 4 percent each. That 'I was so close' effect keeps people swapping."

---

## Slide 4｜LP 價值論證（0:38-0:52）
**畫面**：PPT Slide 4 — "LP Value: The Critical Defense"
**口白**：
"The number one question: doesn't this dilute LP returns? No. In simulation, when the lottery multiplier exceeds 1.2x, LP fee revenue beats traditional pools by 15 to 30 percent. The volume surge from lottery-driven trading more than compensates. The 0.01 percent tax is a growth investment, not a cost."

---

## Slide 5｜隨機數倫理（0:52-1:05）
**畫面**：PPT Slide 5 — "Randomness: Engineering Ethics"
**口白**：
"We're honest about our boundaries. The hackathon demo uses pseudo-random from block.prevrandao — good enough for testnet, not for mainnet. Production would integrate Chainlink VRF for cryptographically verifiable randomness. X Layer natively supports these oracle networks. We know where the line is, and we draw it clearly."

---

## Slide 6｜飛輪終局（1:05-1:15）
**畫面**：PPT Slide 6 — "The Flywheel Endgame"
**口白**：
"This creates a compounding flywheel. More trades grow the prize pool. Bigger prizes attract more traders. Higher volume generates more LP fees. Better returns attract more liquidity. Tighter spreads bring even more traders. A self-reinforcing loop."

---

## Slide 7｜合約架構（1:15-1:25）
**畫面**：PPT Slide 7 — "Smart Contract Architecture"
**口白**：
"The entire hook is 7.6 kilobytes of Solidity. beforeSwap sets the dynamic fee, PoolManager executes the swap, afterSwap runs the lottery logic — claiming the 0.01 percent ticket and checking if the Dynamic-N trigger fires. Clean, auditable, on-chain."

---

## Slide 8｜部署證明（1:25-1:38）
**畫面**：PPT Slide 8 — "Deployed on X Layer Testnet" + 終端機 `forge test` 截圖
**口白**：
"Deployed on X Layer testnet with verifiable contract addresses. PoolManager, test tokens, and the SwapLotteryHook are all live. Four out of four tests passing. Every callback traceable on-chain. Open the explorer and verify for yourself."

---

## Slide 9｜限制與路線（1:38-1:48）
**畫面**：PPT Slide 9 — "Known Limitations & Production Roadmap"
**口白**：
"We know what needs to improve. Pseudo-random goes to Chainlink VRF. Single-currency tracking splits into dual-currency. The ten-loop consolation draw gets batch optimization. And we have a clear four-stage roadmap from audit to mainnet beta to full dApp launch."

---

## Slide 10｜結尾（1:48-1:55）
**畫面**：PPT Slide 10 — "Every Swap Is a Ticket. Every LP Is a Winner."
**口白**：
"Swap Lottery Hook. Every swap is a ticket. Every LP is a winner. Thank you."


# X (Twitter) 推文文案

## 推文 1（主推文 — 提交時發）

```
🪝 Introducing Swap Lottery Hook

Every swap on Uniswap V4 becomes a lottery ticket.

0.01% invisible tax → Dynamic-N trigger → Multi-tier prizes
60% Grand Prize + 10×4% Consolation

LPs earn MORE through volume surge, not less.

Built for @XLayerOfficial × @Uniswap × @flapdotsh
Deployed on X Layer Testnet ↓

#HookTheFuture #UniswapV4 #XLayer
```

## 推文 2（技術亮點，可作為回覆串）

```
⚙️ Tech Stack:

→ Uniswap V4 afterSwap callback
→ Dynamic N curve: N ∈ [100, 200], psychology-driven
→ Pseudo-random (demo) → Chainlink VRF (production)
→ 4/4 tests passing, 7.6 KB on-chain

Contract: 0x2D78...90C4
```

## 推文 3（附圖說明，可連 PO 截圖）

```
📊 The LP Math:

Traditional pool: 12% APR, flat
Lottery pool: 15-18% APR, compounding

When lottery multiplier > 1.2×, LP fee revenue
beats static pools by 15-30% — even after deductions.

The 0.01% is a growth investment, not a cost.
```

---

## 提交清單

- [ ] 開 X 帳號，發推文標記 @XLayerOfficial @Uniswap @flapdotsh
- [ ] 錄 Demo 影片（照上方腳本，可用 QuickTime 螢幕錄製 + 語音旁白）
- [ ] 上傳影片到 YouTube（未公開）或 Google Drive（公開連結）
- [ ] 填寫 Google Form 提交（需要合約地址、影片連結、項目描述）
- [ ] 在 oklink 驗證合約（加分項）
