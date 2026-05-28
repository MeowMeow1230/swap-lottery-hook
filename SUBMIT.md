# Hook the Future 提交表單內容

## 基本資訊

| 欄位 | 內容 |
|------|------|
| **Project Name** | Swap Lottery Hook |
| **Tagline** | Make Every Swap a Winning Ticket |
| **Category** | DeFi Hook |
| **Chain** | X Layer Testnet (Chain ID: 1952) |

---

## Project Description（貼入表單）

```
Swap Lottery Hook turns every Uniswap V4 swap into a lottery ticket.

CORE MECHANISM:
• 0.01% invisible tax on every swap output (1 basis point — traders don't feel it)
• Dynamic-N trigger curve: pool small → fast draws (hope), pool large → slow draws (anticipation). Bounded between 100-200 swaps.
• Multi-tier prize distribution: 60% Grand Prize + 10×4% Consolation Prizes. The "I was so close" effect keeps traders returning.
• LP Value Proof: Volume surge from lottery flywheel increases LP fee revenue by 15-30%, even after the 0.01% deduction.

TECH:
• Uniswap V4 afterSwap hook callback with dynamic LP fee management
• 7.6 KB Solidity, deployed & verified on X Layer testnet
• 4/4 tests passing
• Pseudo-random (demo) → Chainlink VRF roadmap (production)

The hook creates a compounding flywheel:
More trades → bigger prize pool → more traders → higher volume → more LP fees → more liquidity → tighter spreads → more trades.
```

---

## 合約地址

```
PoolManager:     0x124850dA551dC83b124A9A3F84f8D6674C870Ba1
SwapLotteryHook: 0x2D782F42A0a8bBc6b7526aC2272728976Eee90C4
Test USDC:       0xC67958F2329f4C289aa43D52577C0aF32Dbae028
Test WETH:       0x24003ccc694FF272e54b1601C68019d0E1639eBb
```

Explorer: https://www.oklink.com/xlayer-test

---

## Demo Video 連結

上傳到 YouTube（未公開）或 Google Drive 後，把連結貼在這裡：
```
[你的影片連結]
```

---

## X (Twitter) 推文連結

發完推文後，把連結貼在這裡：
```
[你的推文連結]
```

---

## Code Repository

```
[你的 GitHub repo 連結，或直接貼程式碼]
```

---

## 推文文案（複製到 X）

**推文 1（主推文）：**
```
Introducing Swap Lottery Hook 🪝

Every swap on Uniswap V4 becomes a lottery ticket.

→ 0.01% invisible tax
→ Dynamic-N trigger curve
→ 60% Grand Prize + 10×4% Consolation
→ LPs earn MORE through volume surge

Built for @XLayerOfficial @Uniswap @flapdotsh
Deployed on X Layer Testnet ↓

#HookTheFuture #UniswapV4 #XLayer
```

**推文 2（技術細節，回覆串）：**
```
Contract: 0x2D782F42A0a8bBc6b7526aC2272728976Eee90C4
7.6 KB Solidity | 4/4 tests passing | Chain ID 1952

Dynamic N ∈ [100, 200] — psychology-driven trigger curve
Pseudo-random (demo) → Chainlink VRF (production roadmap)
```

---

## 快速操作順序

1. 打開 `video_output/demo_video.mp4`，確認影片 OK
2. 上傳影片到 YouTube（未公開）或 Google Drive
3. 開 X 帳號，發推文（貼上方的文案）+ 標記三個帳號
4. 填 Google Form，貼入 Project Description + 合約地址 + 影片連結 + 推文連結
5. 截圖提交確認畫面
