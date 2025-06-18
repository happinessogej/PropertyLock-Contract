# PropertyLock Smart Contract

A decentralized real estate listing and verification platform built on Stacks blockchain.

## Overview

PropertyLock enables secure property listings, broker management, and transaction tracking through smart contracts. The platform ensures document verification and maintains transparent property records on the blockchain.

## Features

- Property Listing Management
- Document Verification System  
- Broker Access Control
- Transaction History Tracking
- Owner-based Security Controls

## Contract Functions

### Administrative Functions

`list-property (property-id uint) (price uint) (document-hash (string-ascii 64))`
- Lists a new property with specified ID, price and document hash
- Restricted to contract owner
- Returns success/failure status

`verify-property (property-id uint)`
- Verifies property documents for given property ID
- Restricted to contract owner
- Updates verification status

`register-broker (broker principal) (access-level uint)`
- Registers new broker with specified access level
- Restricted to contract owner
- Returns success/failure status

### Read Functions

`get-property (property-id uint)`
- Returns property details including:
  - Owner
  - Price
  - Status
  - Document hash
  - Verification status

`get-broker (broker principal)`
- Returns broker information including:
  - Access level
  - Active status

`is-verified-broker (broker principal)`
- Checks if specified broker is verified
- Returns boolean status

