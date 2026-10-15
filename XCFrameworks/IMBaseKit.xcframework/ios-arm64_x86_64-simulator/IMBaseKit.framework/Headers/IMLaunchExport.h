//
//  IMLaunchExport.h
//  IMBaseKit
//
//  Created by Jiangqi on 2026/6/18.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN


typedef struct {
    char * _Nonnull key;
    char * _Nonnull name;
    void (* _Nonnull function)(void);
} IMExportedFunction;

/// 将启动函数写入 Mach-O 自定义段，模块加载后由 IMLaunchManager 统一调度。
/// section 名为 `__<key>`，调用 launch(forKey:) 时传入不带前缀的 key。
#define IM_FUNCTION_EXPORT(key, name) \
static void _IM##key##_##name(void); \
__attribute__((used, section("__DATA," "__"#key))) \
static const IMExportedFunction __IMFunc##key##_##name = {(char *)(#key), (char *)(#name), (void *)(&_IM##key##_##name)}; \
static void _IM##key##_##name(void)


@interface IMLaunchExecutor : NSObject

+ (int)executeFunctionsForSectionKey:(NSString *)sectionKey
                              before:(void (^ _Nullable)(NSString *name))before
                               after:(void (^ _Nullable)(NSString *name))after;

@end

NS_ASSUME_NONNULL_END
