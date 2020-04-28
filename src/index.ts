//@ts-ignore
import { NativeModules } from 'react-native';

const { Phasset } = NativeModules;

export interface AssetParams {
  id: string;
  assetType?: 'all' | 'videos' | 'photos';
  groupTypes?: 'album' | 'all' | 'event' | 'faces' | 'library' | 'photostream' | 'savedphotos';
  groupName?: string;
}

export interface ImageRequestParams extends AssetParams {
  maxWidth?: number;
  maxHeight?: number;
  useBase64?: boolean;
}

function isExists({ id, assetType = 'all', groupTypes = 'all', ...others }: AssetParams) {
  return Phasset.checkExists({
    id,
    assetType,
    groupTypes,
    ...others,
  });
}

function requestImage(params: ImageRequestParams) {
  return Phasset.requestImage(params);
}

export default {
  isExists,
  requestImage,
};
