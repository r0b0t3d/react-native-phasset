//@ts-ignore
import { NativeModules } from 'react-native';

const { Phasset } = NativeModules;

export interface AssetParams {
  id: string;
  assetType?: 'all' | 'videos' | 'photos';
}

export interface ImageRequestParams extends AssetParams {
  maxWidth?: number;
  maxHeight?: number;
}

function isExists({ id, assetType = 'all' }: AssetParams) {
  return Phasset.checkExists({
    id,
    assetType,
  });
}

function requestImage(params: ImageRequestParams) {
  return Phasset.requestImage(params);
}

export default {
  isExists,
  requestImage,
};
