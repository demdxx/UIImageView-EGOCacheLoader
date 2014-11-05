/**
 * UIImageView+EGOCacheLoader.h
 * UIImageView cache using EGOCache and AFNetworking
 *
 * @author Dmitry Ponomarev <demdxx@gmail.com>
 * @license MIT Copyright (c) 2013 demdxx. All rights reserved.
 *
 *
 * Copyright (C) <2013> Dmitry Ponomarev <demdxx@gmail.com>
 *
 * Permission is hereby granted, free of charge, to any person obtaining a copy
 * of this software and associated documentation files (the "Software"), to deal
 * in the Software without restriction, including without limitation the rights
 * to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 * copies of the Software, and to permit persons to whom the Software is
 * furnished to do so, subject to the following conditions:
 *
 * The above copyright notice and this permission notice shall be included in
 * all copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
 * SOFTWARE.
 */

#import "UIImageView+EGOCacheLoader.h"

#import <NSHelpers/NSString+Hashes.h>
#import <EGOCache/EGOCache.h>
#import <AFNetworking/UIImageView+AFNetworking.h>
#import <AFNetworking/AFHTTPRequestOperation.h>

#ifndef __has_feature
#define __has_feature(x) 0
#endif

#if __has_feature(objc_arc)
#define EGOUIV_OBJECT_RETAIN(obj) obj
#define EGOUIV_OBJECT_AUTORELEASE(obj) obj
#else
#define EGOUIV_OBJECT_RETAIN(obj) [obj retain]
#define EGOUIV_OBJECT_AUTORELEASE(obj) [obj autorelease]
#endif

@implementation UIImageView (EGOCacheLoader)

- (UIImageView *)setCacheImageWithURL:(NSURL *)url
{
  return [self setCacheImageWithURL:url
                   placeholderImage:nil
                         errorImage:nil
                              cache:nil
                           callback:nil];
}

- (UIImageView *)setCacheImageWithURL:(NSURL *)url
                             callback:(void(^)(UIImage *image, NSError* error))callback
{
  return [self setCacheImageWithURL:url
                   placeholderImage:nil
                         errorImage:nil
                              cache:nil
                           callback:callback];
}

- (UIImageView *)setCacheImageWithURL:(NSURL *)url
                     placeholderImage:(UIImage *)holdImage
                           errorImage:(UIImage *)errorImage
                             callback:(void(^)(UIImage *image, NSError* error))callback
{
  return [self setCacheImageWithURL:url
                   placeholderImage:holdImage
                         errorImage:errorImage
                              cache:nil
                           callback:callback];
}

- (UIImageView *)setCacheImageWithURL:(NSURL *)url
                     placeholderImage:(UIImage *)holdImage
                           errorImage:(UIImage *)errorImage
                                cache:(id)cache
                             callback:(void(^)(UIImage *image, NSError* error))callback
{
  if (nil==cache) {
    cache = [EGOCache globalCache];
  }
  
  // Image cache key
  NSString *key = [url.absoluteString md5];
  
  // Get image from cache
  UIImage *image = [cache imageForKey:key];
  
  if (nil != image) {
    // Set image from cache
    [self setImage:image];
    
    // Caclback
    if (nil != callback) {
      callback(image, nil);
    }
  } else {
    // Make request
    NSURLRequest *request = [NSURLRequest requestWithURL:url];
    
    // Use AFNetworking for load image
    [self setImageWithURLRequest:request
                placeholderImage:holdImage
                         success:^(NSURLRequest *rq, NSHTTPURLResponse *r, UIImage *img) {
                           if(nil == img) {
                             if ([self respondsToSelector:@selector(af_imageRequestOperation)]) {
                               id resp = [self performSelector:@selector(af_imageRequestOperation)];
                               if ([resp respondsToSelector:@selector(responseData)]) {
                                 img = EGOUIV_OBJECT_AUTORELEASE(EGOUIV_OBJECT_RETAIN([UIImage imageWithData:[resp performSelector:@selector(responseData)]]));
                               }
                             }
                           }
                           if (nil != img) {
                             [cache setImage:img forKey:key];
                             [self setImage:img];
                           } else if (nil != errorImage) {
                             [self setImage:errorImage];
                           }
                           if (nil != callback) {
                             callback(img, nil);
                           }
                         }
                         failure:^(NSURLRequest *rq, NSHTTPURLResponse *r, NSError *e) {
                           if (nil != callback) {
                             callback(nil, e);
                           }
                         }];
  }
  return self;
}

- (UIImageView *)setCacheImageWithURL:(NSURL *)url
                     placeholderImage:(UIImage *)holdImage
                           errorImage:(UIImage *)errorImage
                                cache:(id)cache
                             callback:(void(^)(UIImage *image, NSError* error))callback
                              decoder:(UIImage*(^)(NSData *data))decoder
{
  if (nil == decoder) {
    return [self setCacheImageWithURL:url
                     placeholderImage:holdImage
                           errorImage:errorImage
                                cache:cache
                             callback:callback];
  }
  
  if (nil==cache) {
    cache = [EGOCache globalCache];
  }
  
  // Image cache key
  NSString *key = [url.absoluteString md5];
  
  // Get image from cache
  NSData *data = [cache dataForKey:key];
  
  if (nil != data) {
    UIImage *image = decoder (data);
    
    // Set image from cache
    if (image != nil) {
      [self setImage:image];
    } else if (nil != errorImage) {
      [self setImage:errorImage];
    }
    
    // Caclback
    if (nil != callback) {
      callback(image, nil);
    }
  } else {
    // Make request
    NSURLRequest *request = [NSURLRequest requestWithURL:url];
    AFHTTPRequestOperation *operation = EGOUIV_OBJECT_AUTORELEASE([[AFHTTPRequestOperation alloc] initWithRequest:request]);
    [operation setCompletionBlockWithSuccess:^(AFHTTPRequestOperation *operation, id responseObject) {
      UIImage *image = decoder (operation.responseData);
      
      // Set image from cache
      if (image != nil) {
        [self setImage:image];
        [cache setData:operation.responseData forKey:key];
      } else if (nil != errorImage) {
        [self setImage:errorImage];
      }
      
      // Caclback
      if (nil != callback) {
        callback(image, nil);
      }
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
      if (nil != callback) {
        callback(nil, error);
      }
    }];
    
    NSOperationQueue *queue = EGOUIV_OBJECT_AUTORELEASE([[NSOperationQueue alloc] init]);
    [queue addOperation:operation];
  }
  
  return self;
}

@end
