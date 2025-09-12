import { describe, expect, it, beforeEach } from "vitest";
import { Cl } from "@stacks/transactions";

const accounts = simnet.getAccounts();
const deployer = accounts.get("deployer")!;
const user1 = accounts.get("wallet_1")!;
const user2 = accounts.get("wallet_2")!;
const user3 = accounts.get("wallet_3")!;

describe("PropertyValuation Contract", () => {

    beforeEach(() => {
        // Set up property factors for testing
        simnet.callPublicFn(
            "PropertyValuation",
            "set-property-factors",
            [
                Cl.uint(1),     // property-id
                Cl.uint(85),    // location-score
                Cl.uint(2000),  // size-sqft
                Cl.uint(3),     // bedrooms
                Cl.uint(2),     // bathrooms
                Cl.uint(10),    // age-years
                Cl.uint(90),    // condition-score
                Cl.uint(80),    // amenities-score
                Cl.uint(85)     // neighborhood-score
            ],
            user1
        );
    });

    describe("Property Factors Management", () => {
        it("allows setting property factors with valid inputs", () => {
            const setFactorsCall = simnet.callPublicFn(
                "PropertyValuation",
                "set-property-factors",
                [
                    Cl.uint(2),
                    Cl.uint(90),
                    Cl.uint(2500),
                    Cl.uint(4),
                    Cl.uint(3),
                    Cl.uint(5),
                    Cl.uint(95),
                    Cl.uint(85),
                    Cl.uint(90)
                ],
                user1
            );
            expect(setFactorsCall.result).toHaveProperty('type', 7);
        });

        it("rejects property factors with zero size", () => {
            const setFactorsCall = simnet.callPublicFn(
                "PropertyValuation",
                "set-property-factors",
                [
                    Cl.uint(3),
                    Cl.uint(85),
                    Cl.uint(0),     // Invalid size
                    Cl.uint(3),
                    Cl.uint(2),
                    Cl.uint(10),
                    Cl.uint(90),
                    Cl.uint(80),
                    Cl.uint(85)
                ],
                user1
            );
            expect(setFactorsCall.result).toHaveProperty('type', 8);
        });

        it("rejects property factors with invalid scores over 100", () => {
            const setFactorsCall = simnet.callPublicFn(
                "PropertyValuation",
                "set-property-factors",
                [
                    Cl.uint(4),
                    Cl.uint(105),   // Invalid location score
                    Cl.uint(2000),
                    Cl.uint(3),
                    Cl.uint(2),
                    Cl.uint(10),
                    Cl.uint(90),
                    Cl.uint(80),
                    Cl.uint(85)
                ],
                user1
            );
            expect(setFactorsCall.result).toHaveProperty('type', 8);
        });


    });

    describe("Property Valuation Calculations", () => {
        it("successfully calculates automated property valuation", () => {
            const calculateCall = simnet.callPublicFn(
                "PropertyValuation",
                "calculate-property-valuation",
                [
                    Cl.uint(1),     // property-id
                    Cl.uint(200),   // base-price-per-sqft
                    Cl.uint(110)    // market-multiplier (110%)
                ],
                user1
            );
            expect(calculateCall.result).toHaveProperty('type', 7);
        });

        it("fails when property factors not set", () => {
            const calculateCall = simnet.callPublicFn(
                "PropertyValuation",
                "calculate-property-valuation",
                [
                    Cl.uint(99),    // Non-existent property
                    Cl.uint(200),
                    Cl.uint(110)
                ],
                user1
            );
            expect(calculateCall.result).toHaveProperty('type', 8);
        });

    });

    describe("Professional Valuations", () => {
        it("allows professional valuation with valid inputs", () => {
            const professionalCall = simnet.callPublicFn(
                "PropertyValuation",
                "professional-valuation",
                [
                    Cl.uint(1),
                    Cl.uint(500000),
                    Cl.stringAscii("appraisal"),
                    Cl.stringAscii("Professional appraisal conducted")
                ],
                user1
            );
            expect(professionalCall.result).toHaveProperty('type', 7);
        });

        it("rejects professional valuation with zero amount", () => {
            const professionalCall = simnet.callPublicFn(
                "PropertyValuation",
                "professional-valuation",
                [
                    Cl.uint(1),
                    Cl.uint(0),     // Invalid amount
                    Cl.stringAscii("appraisal"),
                    Cl.stringAscii("Professional appraisal conducted")
                ],
                user1
            );
            expect(professionalCall.result).toHaveProperty('type', 8);
        });
    });

    describe("Comparable Properties", () => {
        it("successfully adds comparable property", () => {
            const addComparableCall = simnet.callPublicFn(
                "PropertyValuation",
                "add-comparable-property",
                [
                    Cl.uint(1),     // property-id
                    Cl.uint(1),     // comparable-id
                    Cl.uint(2),     // comparable-property-id
                    Cl.uint(95),    // distance-factor
                    Cl.uint(105),   // size-factor
                    Cl.uint(110),   // age-factor
                    Cl.uint(100),   // condition-factor
                    Cl.uint(480000), // adjusted-price
                    Cl.uint(80)     // weight
                ],
                user1
            );
            expect(addComparableCall.result).toHaveProperty('type', 7);
        });

        it("rejects comparable with invalid factors over limits", () => {
            const addComparableCall = simnet.callPublicFn(
                "PropertyValuation",
                "add-comparable-property",
                [
                    Cl.uint(1),
                    Cl.uint(1),
                    Cl.uint(2),
                    Cl.uint(101),   // Invalid distance factor over 100
                    Cl.uint(105),
                    Cl.uint(110),
                    Cl.uint(100),
                    Cl.uint(480000),
                    Cl.uint(80)
                ],
                user1
            );
            expect(addComparableCall.result).toHaveProperty('type', 8);
        });


    });

    describe("Market Trends", () => {
        it("allows deployer to update market trends", () => {
            const updateTrendsCall = simnet.callPublicFn(
                "PropertyValuation",
                "update-market-trends",
                [
                    Cl.uint(10001),         // area-code
                    Cl.uint(202401),        // period
                    Cl.uint(450000),        // average-price
                    Cl.uint(5),             // price-change (5%)
                    Cl.uint(75),            // sales-volume
                    Cl.uint(25),            // days-on-market
                    Cl.stringAscii("up"),   // trend-direction
                    Cl.uint(50)             // data-points
                ],
                deployer
            );
            expect(updateTrendsCall.result).toHaveProperty('type', 7);
        });

        it("rejects market trends update from non-deployer", () => {
            const updateTrendsCall = simnet.callPublicFn(
                "PropertyValuation",
                "update-market-trends",
                [
                    Cl.uint(10001), Cl.uint(202401), Cl.uint(450000),
                    Cl.uint(5), Cl.uint(75), Cl.uint(25),
                    Cl.stringAscii("up"), Cl.uint(50)
                ],
                user1
            );
            expect(updateTrendsCall.result).toHaveProperty('type', 8);
        });

        it("rejects market trends with zero data points", () => {
            const updateTrendsCall = simnet.callPublicFn(
                "PropertyValuation",
                "update-market-trends",
                [
                    Cl.uint(10001), Cl.uint(202401), Cl.uint(450000),
                    Cl.uint(5), Cl.uint(75), Cl.uint(25),
                    Cl.stringAscii("up"), Cl.uint(0)  // Invalid data points
                ],
                deployer
            );
            expect(updateTrendsCall.result).toHaveProperty('type', 8);
        });


    });

    describe("Price Predictions", () => {
        it("successfully generates price predictions", () => {
            const predictionsCall = simnet.callPublicFn(
                "PropertyValuation",
                "generate-price-predictions",
                [
                    Cl.uint(1),         // property-id
                    Cl.uint(500000),    // current-value
                    Cl.uint(8),         // market-growth-rate (8%)
                    Cl.uint(15)         // volatility-factor (15%)
                ],
                user1
            );
            expect(predictionsCall.result).toHaveProperty('type', 7);
        });

       
    });

    describe("Valuation History", () => {
        it("correctly retrieves valuation history entry", () => {
            // First create a valuation to generate history
            simnet.callPublicFn(
                "PropertyValuation",
                "calculate-property-valuation",
                [Cl.uint(1), Cl.uint(200), Cl.uint(110)],
                user1
            );

            const getHistoryCall = simnet.callReadOnlyFn(
                "PropertyValuation",
                "get-valuation-history",
                [Cl.uint(1), Cl.uint(1)],
                user1
            );
            expect(getHistoryCall.result).toHaveProperty('type', 10);
        });
    });

    describe("Market Health Analysis", () => {
        it("calculates market health score for existing trends", () => {
            // First update market trends
            simnet.callPublicFn(
                "PropertyValuation",
                "update-market-trends",
                [
                    Cl.uint(10001), Cl.uint(202401), Cl.uint(450000),
                    Cl.uint(5), Cl.uint(60), Cl.uint(20),
                    Cl.stringAscii("up"), Cl.uint(25)
                ],
                deployer
            );

            const healthScoreCall = simnet.callReadOnlyFn(
                "PropertyValuation",
                "get-market-health-score",
                [Cl.uint(10001), Cl.uint(202401)],
                user1
            );
            expect(healthScoreCall.result).toHaveProperty('type', 7);
        });

        it("returns error for non-existent market trends", () => {
            const healthScoreCall = simnet.callReadOnlyFn(
                "PropertyValuation",
                "get-market-health-score",
                [Cl.uint(99999), Cl.uint(999999)],
                user1
            );
            expect(healthScoreCall.result).toHaveProperty('type', 8);
        });
    });

    describe("Value Appreciation Calculations", () => {
        it("correctly calculates appreciation with positive growth", () => {
            const appreciationCall = simnet.callReadOnlyFn(
                "PropertyValuation",
                "calculate-appreciation",
                [
                    Cl.uint(400000),    // original-value
                    Cl.uint(450000),    // current-value
                    Cl.uint(12)         // time-period (months)
                ],
                user1
            );
            expect(appreciationCall.result).toHaveProperty('type', 7);
        });

        it("handles zero appreciation correctly", () => {
            const appreciationCall = simnet.callReadOnlyFn(
                "PropertyValuation",
                "calculate-appreciation",
                [
                    Cl.uint(400000),    // same values
                    Cl.uint(400000),
                    Cl.uint(12)
                ],
                user1
            );
            expect(appreciationCall.result).toHaveProperty('type', 7);
        });

        it("handles negative value change correctly", () => {
            const appreciationCall = simnet.callReadOnlyFn(
                "PropertyValuation",
                "calculate-appreciation",
                [
                    Cl.uint(450000),    // higher original value
                    Cl.uint(400000),    // lower current value
                    Cl.uint(12)
                ],
                user1
            );
            expect(appreciationCall.result).toHaveProperty('type', 7);
        });
    });

    describe("Valuation Currency Check", () => {
        it("correctly identifies recent valuations", () => {
            // First create a valuation
            simnet.callPublicFn(
                "PropertyValuation",
                "calculate-property-valuation",
                [Cl.uint(1), Cl.uint(200), Cl.uint(110)],
                user1
            );

            const recentCheck = simnet.callReadOnlyFn(
                "PropertyValuation",
                "is-valuation-recent",
                [Cl.uint(1), Cl.uint(100)],  // Allow up to 100 blocks age
                user1
            );
            expect(recentCheck.result).toHaveProperty('type', 7);
        });

        it("returns error for non-existent property valuation", () => {
            const recentCheck = simnet.callReadOnlyFn(
                "PropertyValuation",
                "is-valuation-recent",
                [Cl.uint(99), Cl.uint(100)],
                user1
            );
            expect(recentCheck.result).toHaveProperty('type', 8);
        });
    });
});
