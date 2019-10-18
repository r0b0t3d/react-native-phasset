export interface AssetParams {
    id: string;
    assetType?: 'all' | 'videos' | 'photos';
    groupTypes?: 'album' | 'all' | 'event' | 'faces' | 'library' | 'photostream' | 'savedphotos';
    groupName?: string;
}
export interface ImageRequestParams extends AssetParams {
    maxWidth?: number;
    maxHeight?: number;
}
declare function isExists({ id, assetType, groupTypes, ...others }: AssetParams): any;
declare function requestImage(params: ImageRequestParams): any;
declare const _default: {
    isExists: typeof isExists;
    requestImage: typeof requestImage;
};
export default _default;
