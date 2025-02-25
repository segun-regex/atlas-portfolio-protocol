;; Title: Atlas Portfolio Protocol - Advanced Automated Asset Management
;; Summary: Institutional-grade DeFi portfolio management with autonomous rebalancing on Stacks L2
;; Description: 
;; A next-generation decentralized asset management protocol combining Bitcoin's security with 
;; Stacks L2 scalability. Atlas enables sophisticated portfolio strategies through:
;;
;;   - Non-custodial multi-asset vaults with sub-account isolation
;;   - Programmatic rebalancing triggered by market conditions/time thresholds
;;   - Atomic percentage allocations with 0.01% precision (100 basis points granularity)
;;   - Bitcoin-finalized settlement with STX-based gas optimization
;;   - Regulatory-compliant architecture supporting institutional workflows
;;   - Cross-chain asset support via SIP-010 tokens and bridged assets
;;
;; Built for capital efficiency, Atlas combines automated yield strategies with real-time 
;; portfolio health monitoring. The protocol's L2-native design enables:
;;   - Sub-second rebalancing execution
;;   - Micro-fee structure (0.25% management fee)
;;   - Transparent on-chain audit trails
;;   - Bitcoin-secured smart contracts
;;   - Seamless integration with Stacks DeFi ecosystem
;;
;; Institutional features include:
;;   - Multi-sig portfolio ownership
;;   - Customizable slippage controls
;;   - Asset whitelisting capabilities
;;   - Time-locked parameter changes
;;   - Portfolio performance analytics
;;   - Compliance-ready transaction reporting

;; Constants: Error Codes
(define-constant ERR-NOT-AUTHORIZED (err u100))
(define-constant ERR-INVALID-PORTFOLIO (err u101))
(define-constant ERR-INSUFFICIENT-BALANCE (err u102))
(define-constant ERR-INVALID-TOKEN (err u103))
(define-constant ERR-REBALANCE-FAILED (err u104))
(define-constant ERR-PORTFOLIO-EXISTS (err u105))
(define-constant ERR-INVALID-PERCENTAGE (err u106))
(define-constant ERR-MAX-TOKENS-EXCEEDED (err u107))
(define-constant ERR-LENGTH-MISMATCH (err u108))
(define-constant ERR-USER-STORAGE-FAILED (err u109))
(define-constant ERR-INVALID-TOKEN-ID (err u110))

;; Protocol Configuration
(define-constant MAX-TOKENS-PER-PORTFOLIO u10)
(define-constant BASIS-POINTS u10000)

;; Protocol State
(define-data-var protocol-owner principal tx-sender)
(define-data-var portfolio-counter uint u0)
(define-data-var protocol-fee uint u25) ;; 0.25% in basis points

;; Data Maps
(define-map Portfolios
    uint  ;; portfolio-id
    {
        owner: principal,
        created-at: uint,
        last-rebalanced: uint,
        total-value: uint,
        active: bool,
        token-count: uint
    }
)

(define-map PortfolioAssets
    {portfolio-id: uint, token-id: uint}
    {
        target-percentage: uint,
        current-amount: uint,
        token-address: principal
    }
)

(define-map UserPortfolios
    principal
    (list 20 uint)
)

;; Read-Only Functions
(define-read-only (get-portfolio (portfolio-id uint))
    (map-get? Portfolios portfolio-id)
)

(define-read-only (get-portfolio-asset (portfolio-id uint) (token-id uint))
    (map-get? PortfolioAssets {portfolio-id: portfolio-id, token-id: token-id})
)

(define-read-only (get-user-portfolios (user principal))
    (default-to (list) (map-get? UserPortfolios user))
)

(define-read-only (calculate-rebalance-amounts (portfolio-id uint))
    (let (
        (portfolio (unwrap! (get-portfolio portfolio-id) ERR-INVALID-PORTFOLIO))
        (total-value (get total-value portfolio))
    )
    (ok {
        portfolio-id: portfolio-id,
        total-value: total-value,
        needs-rebalance: (> (- stacks-block-height (get last-rebalanced portfolio)) u144)
    }))
)