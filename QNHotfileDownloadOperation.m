//
//  QNHotfileDownloadOperation.m
//  QuantumNoise
//
//  Created by jrk on 24/7/10.
//  Copyright (c) 2010 __MyCompanyName__. All rights reserved.
//

#import "QNHotfileDownloadOperation.h"
#import "QNDownloadOperation+Private.h"
#import "NSString+Additions.h"

#pragma mark C99 curl callbacks
size_t hotfile_login_write_data_callback (void *buffer, size_t size, size_t nmemb, void *inSelf)
{
	QNHotfileDownloadOperation *me = (QNHotfileDownloadOperation *)inSelf;
	
	return [me hotfileLoginWriteDataCallbackWithDataPointer: buffer blockSize: size numberOfBlocks: nmemb];
}

@implementation QNHotfileDownloadOperation

/*
 will save the received data (the login anwer page) into receivedData
 which can be parsed later in main:
 */
- (size_t) hotfileLoginWriteDataCallbackWithDataPointer: (void *) data blockSize: (size_t) blockSize numberOfBlocks: (size_t) numberOfBlocks
{
	//save data >.<
	[receivedData appendBytes: data length: (blockSize * numberOfBlocks)];
	return blockSize * numberOfBlocks;
}

/*
 will try to login to hotfile premium and get a premium cookie for the following download
 
 
 */

- (BOOL) performRemoteLogin
{
	if (!curlHandle)
		return NO;
    
	//NSString *username = [[NSUserDefaults standardUserDefaults] objectForKey: @"hotfile_username"];
	//NSString *password =  [[NSUserDefaults standardUserDefaults] objectForKey: @"hotfile_password"];
    
    NSString *username = @"2556583";
    NSString *password = @"jcwlhi";
	
	if (!username || !password)
	{
		[self setStatus: @"Login Failed: No Credentials Found for Hotfile.com"];
		
		[self setOperationError: [self errorWithDescription: [self status] code: 1 andErrorLevel: kQNDownloadOperationErrorRecoverable]];
		
		return NO;
	}
	
	
    

	///////////////////////////////////////////////////////////////////////////
	// Login + Cookie generation
	//////////////////////////////////////////////////////////////////////////
	[self setStatus: @"Logging in"];
    
	NSString *loginDataString = [NSString stringWithFormat:@"user=%@&pass=%@",username,password];
	const char *postData = [loginDataString UTF8String];
	
	curl_easy_setopt(curlHandle, CURLOPT_HTTPPOST,1);
	curl_easy_setopt(curlHandle, CURLOPT_POSTFIELDS, postData);
	curl_easy_setopt(curlHandle, CURLOPT_URL, "http://hotfile.com/login.php");
	curl_easy_setopt(curlHandle, CURLOPT_COOKIEFILE,"/tmp/hfcookie"); //ok we're using libcurls cookie storage here. watch out
																	  //when changing the credentials. the cookie store might not get erased. so if you get weird login errors/fuckups with hotfile just look here first
	
	//file writing
	curl_easy_setopt(curlHandle, CURLOPT_WRITEFUNCTION, hotfile_login_write_data_callback);
	curl_easy_setopt(curlHandle, CURLOPT_WRITEDATA, self);
	
	//if you crash here, somebody forgot to set the receivedData refrence to nil
	[receivedData release];
	receivedData = [[NSMutableData alloc] init];
	
	
	/*
	 
	 if the length of receivedData is 0 then the log in was not successful
	 and the free loader page was shown. we can handle it here or let it handle
	 by the download module. (it will recognize that it received html-data and parse
	 the html for an error.)
	 
	 */
	
	CURLcode res = curl_easy_perform(curlHandle);
	NSString *returnString = [[NSString alloc] initWithData: receivedData encoding: NSUTF8StringEncoding];
	[returnString autorelease];
	
	NSLog(@"HF LOGIN returnString: %@",returnString);
	NSString *errorString = nil;//[self errorStringForRapidshareErrorPage: returnString];
    //	NSLog(@"errorstring: %@",errorString);
	
    //lol srsly hf?
    if (![returnString containsString: @"Undefined index:" ignoringCase: YES])
    {
        errorString = @"LOL! hf had no php error ... LOGIN WRONG?!";
    }
    
	[receivedData release];
	receivedData = nil;
	
	printf("HF LOGIN RETURNED: %i = %s\n",res, curl_easy_strerror(res));
	if (res != CURLE_OK)
	{	
		[self setStatus: [NSString stringWithFormat: @"Login Failed: %s", curl_easy_strerror(res)]];
		
		[self setOperationError: [self errorWithDescription: [self status] code: 1 andErrorLevel: kQNDownloadOperationErrorRecoverable]];
		return NO;
	}
	if (errorString)
	{
		[self setStatus: [NSString stringWithFormat:@"Login Failed: %@", errorString]];
        
		[self setOperationError: [self errorWithDescription: [self status] code: 1 andErrorLevel: kQNDownloadOperationErrorRecoverable]];
		return NO;
	}
	
	[self setStatus: @"Login succeeded"];
	return YES;
	
}


//TODO: that's pretty much the same as the super class's method
//maybe we could ommit this and let the super do the work. (we only set here the cookie from the log in)
- (BOOL) performFileDownload
{
	if (!curlHandle)
	{	
		[self setStatus: @"performFileDownload: No curl handle! Fatal!"];
		[self setOperationError: [self errorWithDescription: [self status] code: 1 andErrorLevel: kQNDownloadOperationErrorDontKnow]];
		return NO;
	}
	
	//const char *cookie = [hfCookie cStringUsingEncoding: NSUTF8StringEncoding];
	//printf("cookie: %s\n",cookie);
	//setup curl for http get
	curl_easy_setopt(curlHandle, CURLOPT_HTTPGET,1);
	curl_easy_setopt(curlHandle, CURLOPT_URL, [[self URI] UTF8String]);
	curl_easy_setopt(curlHandle, CURLOPT_FOLLOWLOCATION, 1);
    curl_easy_setopt(curlHandle, CURLOPT_COOKIEFILE,"/tmp/hfcookie");
	
	//
	//curl_easy_setopt(curlHandle, CURLOPT_MAX_RECV_SPEED_LARGE, 250000);
	//header
	curl_easy_setopt(curlHandle, CURLOPT_HEADERFUNCTION, header_callback);
	curl_easy_setopt(curlHandle, CURLOPT_WRITEHEADER, self);
	
	//file writing
	curl_easy_setopt(curlHandle, CURLOPT_WRITEFUNCTION, write_data_callback);
	curl_easy_setopt(curlHandle, CURLOPT_WRITEDATA, self);
	
	//progress
	curl_easy_setopt(curlHandle, CURLOPT_NOPROGRESS, 0);
	curl_easy_setopt(curlHandle, CURLOPT_PROGRESSFUNCTION, progress_callback);
	curl_easy_setopt(curlHandle, CURLOPT_PROGRESSDATA, self);	
	
	CURLcode res = curl_easy_perform(curlHandle);
	
	NSLog(@"CURL DOWNLOAD RETURNED: %i = %s",res, curl_easy_strerror(res));
	
	if (res != CURLE_OK)
	{	
		// if res == CURLE_WRITE_ERROR there was a file writing error
		//and our status/error string is set already. so we won't overwrite them
		//(atm there is no return 0 in the writeHandler so this won't get called)
		if (res != CURLE_WRITE_ERROR) //writing abort through handler return 0
		{	
			[self setStatus: [NSString stringWithFormat: @"Download Failed: %s", curl_easy_strerror(res)]];
			[self setOperationError: [self errorWithDescription: [self status] code: 1 andErrorLevel: kQNDownloadOperationErrorRecoverable]];
		}
		return NO;
	}
	
	return YES;	
}

@end
