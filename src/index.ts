//@ts-ignore
import { NativeModules } from 'react-native';

const { Phasset } = NativeModules;

export type AssetParams = {
  id: string;
};

function requestImage(params: AssetParams) {
  return Phasset.requestImage(params);
}

export default {
  requestImage,
};
