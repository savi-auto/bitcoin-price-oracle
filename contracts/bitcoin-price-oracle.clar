;; Title: Bitcoin Price Oracle - Decentralized Prediction Market
;; Summary: A trustless prediction market for Bitcoin price movements
;; Description: This smart contract enables users to stake STX tokens on 
;;              Bitcoin price direction predictions within defined time windows.
;;              Features oracle-based price resolution, proportional reward 
;;              distribution, and administrative controls for market management.
;;              Built for transparency, fairness, and decentralized governance.

;; CONSTANTS

;; Administrative Constants
(define-constant CONTRACT-OWNER tx-sender)
(define-constant ERR-OWNER-ONLY (err u100))

;; Error Code Definitions
(define-constant ERR-NOT-FOUND (err u101))
(define-constant ERR-INVALID-PREDICTION (err u102))
(define-constant ERR-MARKET-CLOSED (err u103))
(define-constant ERR-ALREADY-CLAIMED (err u104))
(define-constant ERR-INSUFFICIENT-BALANCE (err u105))
(define-constant ERR-INVALID-PARAMETER (err u106))

;; STATE VARIABLES

;; Platform Configuration Variables
(define-data-var oracle-address principal 'ST1PQHQKV0RJXZFY1DGX8MNSNYVE3VGZJSRTPGZGM)
(define-data-var minimum-stake uint u1000000)  ;; 1 STX minimum stake requirement
(define-data-var fee-percentage uint u2)       ;; 2% platform fee on winnings
(define-data-var market-counter uint u0)       ;; Global market ID counter

;; DATA STRUCTURES

;; Market Information Storage
(define-map markets
  uint  ;; market-id
  {
    start-price: uint,      ;; Bitcoin price at market start
    end-price: uint,        ;; Bitcoin price at market resolution
    total-up-stake: uint,   ;; Total STX staked on price increase
    total-down-stake: uint, ;; Total STX staked on price decrease
    start-block: uint,      ;; Block height when predictions open
    end-block: uint,        ;; Block height when predictions close
    resolved: bool,         ;; Market resolution status
  }
)

;; User Prediction Tracking
(define-map user-predictions
  {
    market-id: uint,
    user: principal,
  }
  {
    prediction: (string-ascii 4),  ;; "up" or "down"
    stake: uint,                   ;; Amount of STX staked
    claimed: bool,                 ;; Winnings claim status
  }
)

;; PUBLIC FUNCTIONS

;; Creates a new Bitcoin price prediction market
(define-public (create-market
    (start-price uint)
    (start-block uint)
    (end-block uint)
  )
  (let ((market-id (var-get market-counter)))
    (asserts! (is-eq tx-sender CONTRACT-OWNER) ERR-OWNER-ONLY)
    (asserts! (> end-block start-block) ERR-INVALID-PARAMETER)
    (asserts! (> start-price u0) ERR-INVALID-PARAMETER)
    
    (map-set markets market-id {
      start-price: start-price,
      end-price: u0,
      total-up-stake: u0,
      total-down-stake: u0,
      start-block: start-block,
      end-block: end-block,
      resolved: false,
    })
    
    (var-set market-counter (+ market-id u1))
    (ok market-id)
  )
)

;; Places a prediction stake in an active Bitcoin price market
(define-public (make-prediction
    (market-id uint)
    (prediction (string-ascii 4))
    (stake uint)
  )
  (let (
      (market (unwrap! (map-get? markets market-id) ERR-NOT-FOUND))
      (current-block stacks-block-height)
    )
    ;; Validate market timing
    (asserts!
      (and
        (>= current-block (get start-block market))
        (< current-block (get end-block market))
      )
      ERR-MARKET-CLOSED
    )
    
    ;; Validate prediction parameters
    (asserts! (or (is-eq prediction "up") (is-eq prediction "down"))
      ERR-INVALID-PREDICTION
    )
    (asserts! (>= stake (var-get minimum-stake)) ERR-INVALID-PREDICTION)
    (asserts! (<= stake (stx-get-balance tx-sender)) ERR-INSUFFICIENT-BALANCE)
    
    ;; Transfer stake to contract escrow
    (try! (stx-transfer? stake tx-sender (as-contract tx-sender)))
    
    ;; Record user prediction
    (map-set user-predictions {
      market-id: market-id,
      user: tx-sender,
    } {
      prediction: prediction,
      stake: stake,
      claimed: false,
    })
    
    ;; Update market stake totals
    (map-set markets market-id
      (merge market {
        total-up-stake: (if (is-eq prediction "up")
          (+ (get total-up-stake market) stake)
          (get total-up-stake market)
        ),
        total-down-stake: (if (is-eq prediction "down")
          (+ (get total-down-stake market) stake)
          (get total-down-stake market)
        ),
      })
    )
    
    (ok true)
  )
)

;; Resolves a market with final Bitcoin price from oracle
(define-public (resolve-market
    (market-id uint)
    (end-price uint)
  )
  (let ((market (unwrap! (map-get? markets market-id) ERR-NOT-FOUND)))
    ;; Validate oracle authority and timing
    (asserts! (is-eq tx-sender (var-get oracle-address)) ERR-OWNER-ONLY)
    (asserts! (>= stacks-block-height (get end-block market)) ERR-MARKET-CLOSED)
    (asserts! (not (get resolved market)) ERR-MARKET-CLOSED)
    (asserts! (> end-price u0) ERR-INVALID-PARAMETER)
    
    ;; Update market with resolution data
    (map-set markets market-id
      (merge market {
        end-price: end-price,
        resolved: true,
      })
    )
    
    (ok true)
  )
)

;; Claims proportional winnings from a resolved market
(define-public (claim-winnings (market-id uint))
  (let (
      (market (unwrap! (map-get? markets market-id) ERR-NOT-FOUND))
      (prediction (unwrap!
        (map-get? user-predictions {
          market-id: market-id,
          user: tx-sender,
        })
        ERR-NOT-FOUND
      ))
    )
    ;; Validate market status and claim eligibility
    (asserts! (get resolved market) ERR-MARKET-CLOSED)
    (asserts! (not (get claimed prediction)) ERR-ALREADY-CLAIMED)
    
    (let (
        (winning-prediction (if (> (get end-price market) (get start-price market))
          "up"
          "down"
        ))
        (total-stake (+ (get total-up-stake market) (get total-down-stake market)))
        (winning-stake (if (is-eq winning-prediction "up")
          (get total-up-stake market)
          (get total-down-stake market)
        ))
      )
      ;; Verify user made the winning prediction
      (asserts! (is-eq (get prediction prediction) winning-prediction)
        ERR-INVALID-PREDICTION
      )
      
      (let (
          (winnings (/ (* (get stake prediction) total-stake) winning-stake))
          (fee (/ (* winnings (var-get fee-percentage)) u100))
          (payout (- winnings fee))
        )
        ;; Execute payout transfers
        (try! (as-contract (stx-transfer? payout (as-contract tx-sender) tx-sender)))
        (try! (as-contract (stx-transfer? fee (as-contract tx-sender) CONTRACT-OWNER)))
        
        ;; Mark prediction as claimed
        (map-set user-predictions {
          market-id: market-id,
          user: tx-sender,
        }
          (merge prediction { claimed: true })
        )
        
        (ok payout)
      )
    )
  )
)

;; READ-ONLY FUNCTIONS

;; Retrieves complete market information
(define-read-only (get-market (market-id uint))
  (map-get? markets market-id)
)

;; Retrieves user's prediction details for a specific market
(define-read-only (get-user-prediction
    (market-id uint)
    (user principal)
  )
  (map-get? user-predictions {
    market-id: market-id,
    user: user,
  })
)

;; Returns current contract STX balance
(define-read-only (get-contract-balance)
  (stx-get-balance (as-contract tx-sender))
)

;; Returns current platform configuration
(define-read-only (get-platform-config)
  {
    oracle-address: (var-get oracle-address),
    minimum-stake: (var-get minimum-stake),
    fee-percentage: (var-get fee-percentage),
    market-counter: (var-get market-counter),
  }
)