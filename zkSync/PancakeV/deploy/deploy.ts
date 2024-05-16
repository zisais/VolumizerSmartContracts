import { deployContract } from "./utils";

const poolAddress = "0x3832fB996C49792e71018f948f5bDdd987778424";

// An example of a basic deploy script
// It will deploy a Greeter contract to selected network
// as well as verify it on Block Explorer if possible for the network
export default async function () {
  const contractArtifactName = "Volumizer";
  const constructorArguments = [poolAddress];
  await deployContract(contractArtifactName, constructorArguments);
}
