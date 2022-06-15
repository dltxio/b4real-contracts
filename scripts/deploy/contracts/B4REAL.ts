import { deployContract } from "../utils";

export const contractNames = () => ["B4REAL"];

export const constructorArguments = () => [];

export const deploy = async (deployer, setAddresses) => {
  console.log("deploying B4REAL");
  const token = await deployContract(
    "B4REAL",
    constructorArguments(),
    deployer,
    1
  );
  console.log(`deployed B4REAL to address ${token.address}`);
  setAddresses({ token: token.address });
  return token;
};
