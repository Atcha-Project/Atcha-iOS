#import <Foundation/Foundation.h>

/**
 *타일 획득 타입
 */
typedef NS_ENUM(NSInteger, VSMTileLoaderSource) {
    /** 엔진 내부 정책을 따름
     */
    VSMTileLoaderSourceDefault = 0,
    /** 스트리밍-임베디드 하이브리드
     */
    VSMTileLoaderSourceNetwork,
    /** 임베디드
     */
    VSMTileLoaderSourceEmbedded
};

/**
 *타일 ID
 */
typedef struct {
    uint8_t z;
    uint32_t x, y;
} VSMTileID;

NS_ASSUME_NONNULL_BEGIN

/**
 *타일 로딩 위임 프로토콜
 */
@protocol VSMTileLoaderDelegate <NSObject>

/**
 * 타일 로딩 성공
 * @param data 타일 데이터
 */
-(void)onTileLoaderSuccess:(NSData*)data;

/**
 * 타일 로딩 실패
 * NoError = 0,
 * NetworkError,
 * NotFoundError,
 * TimeoutError,
 * ClientError,
 * ServerError,
 * DataError,
 * OutOfRangeError,
 * OperationCanceled,
 * UnknownError = 1000
 */
-(void)onTileLoaderError:(int32_t)errorCode;

@end

/**
 * 특정 레이어내 특정 타일을 로딩하는 클래스입니다.
 */
@interface VSMTileLoader : NSObject

@property (weak, atomic) id<VSMTileLoaderDelegate> delegate;

/**
 * 초기화 메소드
 * @param layerId 레이어 ID
 * @param tile 타일 ID
 */
-(instancetype)init:(uint32_t)layerId tile:(VSMTileID)tile;

/**
 * 초기화 메소드
 * @param layerId 레이어 ID
 * @param tile 타일 ID
 * @param compressed 압축여부
 */
-(instancetype)init:(uint32_t)layerId tile:(VSMTileID)tile compressed:(BOOL)compressed;

/**
 * 초기화 메소드
 * @param layerId 레이어 ID
 * @param tile 타일 ID
 * @param compressed 압축여부
 * @param source 타일 획득 타입
 */
-(instancetype)init:(uint32_t)layerId tile:(VSMTileID)tile compressed:(BOOL)compressed source:(VSMTileLoaderSource)source;

/**
 * 타일 로딩을 시작합니다.
 */
-(void)load;

@end

NS_ASSUME_NONNULL_END
