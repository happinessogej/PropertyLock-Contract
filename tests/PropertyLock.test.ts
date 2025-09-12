
import { describe, expect, it } from "vitest";
import { Cl } from "@stacks/transactions";

const accounts = simnet.getAccounts();
const address1 = accounts.get("wallet_1")!;

describe("PropertyLock tests", () => {
  it("ensures simnet is well initialised", () => {
    expect(simnet.blockHeight).toBeDefined();
  });

  it("shows an example PropertyLock test", () => {
    const { result } = simnet.callReadOnlyFn("PropertyLock", "get-property", [Cl.uint(1)], address1);
    expect(result).toBeNone();
  });
});
