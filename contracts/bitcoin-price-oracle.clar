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