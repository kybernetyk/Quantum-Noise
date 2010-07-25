//
//  QNRapidshareComDownloadOperation.m
//  DummyDownload
//
//  Created by jrk on 21.09.09.
//  Copyright 2009 flux forge. All rights reserved.
//

#import "QNDownloadOperation.h"
#import "QNRapidshareComDownloadOperation.h"
#import "QNRapidshareComDownloadOperation+Private.h"
#import "QNDownloadOperation+Private.h"
#import "NSString+Additions.h"

#pragma mark C99 curl callbacks
size_t rapidshare_login_write_data_callback (void *buffer, size_t size, size_t nmemb, void *inSelf)
{
	QNRapidshareComDownloadOperation *me = (QNRapidshareComDownloadOperation *)inSelf;
	
	return [me rapidshareLoginWriteDataCallbackWithDataPointer: buffer blockSize: size numberOfBlocks: nmemb];
}

#pragma mark Category implementation
@implementation QNRapidshareComDownloadOperation

/*
 will save the received data (the login anwer page) into receivedData
 which can be parsed later in main:
 */
- (size_t) rapidshareLoginWriteDataCallbackWithDataPointer: (void *) data blockSize: (size_t) blockSize numberOfBlocks: (size_t) numberOfBlocks
{
	//save data >.<
	[receivedData appendBytes: data length: (blockSize * numberOfBlocks)];
	return blockSize * numberOfBlocks;
}

/* will get the cookie from the API's response ... */
/* hello my name is mustafa and I AM A FUCKING RETARDED 12 yo OLD TURKISH KID WHO SCORED A JOB
   AS "CODER" FOR THE RS.COM SUBHUMANS. THE FIRST THING I DID IS TO KILL THE OLD LOG IN SYSTEM (which was pretty much retarded too)
   AND SEND COOKIE STRINGS OVER JAVASCRIPT BULLSHIT FAGGOT GAY RETARD FUCK SO THAT THE CLIENT HAS TO SET THAT COOKIE MANUALLY THEN.
   YES I AM FROM ANKHARA AND MY FATHER FUCKS GOATS FOR A LIVING SO I AM TOOOOO RETARDED TO GET HTTP HEADERS. NOW YOU HAVE TO
   EXTRACT THE COOKIE FROM THE API RESPONSE AND SET IT THEN MANUALLY CAUSE I DROOOOOOOL ALL OVER MY KEYBOARD WHEN I DRAM OF FUCKING
   DONKEYS */
- (NSString *) cookieFromAPIString: (NSString *) APIString
{
	NSArray *apiLines = [APIString componentsSeparatedByCharactersInSet: [NSCharacterSet newlineCharacterSet]];
	
	for (NSString *line in apiLines)
	{
		if ([line containsString: @"cookie" ignoringCase: YES])
		{
			NSLog(@"cookieline = %@",line);
			
			NSArray *linecomps = [line componentsSeparatedByCharactersInSet: [NSCharacterSet characterSetWithCharactersInString: @"="]];
			
			
			return [linecomps lastObject];
		}
	}
	
	return nil;
}


/*
 will try to login to rapidshare premium and get a premium cookie for the following download
 
 
 */
- (BOOL) performRemoteLogin
{
	if (!curlHandle)
		return NO;

	NSString *username = [[NSUserDefaults standardUserDefaults] objectForKey: @"rapidShareCom_username"];
	NSString *password =  [[NSUserDefaults standardUserDefaults] objectForKey: @"rapidShareCom_password"];

	
	if (!username || !password)
	{
		[self setStatus: @"Login Failed: No Credentials Found for Rapidshare.com"];
		
		[self setOperationError: [self errorWithDescription: [self status] code: 1 andErrorLevel: kQNDownloadOperationErrorRecoverable]];
		
		return NO;
	}
	
	

	
	///////////////////////////////////////////////////////////////////////////
	// API Account Check
	//////////////////////////////////////////////////////////////////////////
	[self setStatus: @"Checking Login"];
	NSString *apiURL = [NSString stringWithFormat:
						@"https://api.rapidshare.com/cgi-bin/rsapi.cgi?sub=getaccountdetails_v1&withcookie=1&type=prem&login=%@&password=%@",
						username,
						password];

	curl_easy_setopt(curlHandle, CURLOPT_HTTPGET,1);
	curl_easy_setopt(curlHandle, CURLOPT_URL, [apiURL UTF8String]);
	curl_easy_setopt(curlHandle, CURLOPT_FOLLOWLOCATION, 1);
	
	curl_easy_setopt(curlHandle, CURLOPT_WRITEFUNCTION, rapidshare_login_write_data_callback);
	curl_easy_setopt(curlHandle, CURLOPT_WRITEDATA, self);
	
	[receivedData release];
	receivedData = [[NSMutableData alloc] init];

	CURLcode res = curl_easy_perform(curlHandle);		//receivedData will contain the returned API page
	if (res != CURLE_OK)
	{	
		[self setStatus: [NSString stringWithFormat: @"Login Failed: %s", curl_easy_strerror(res)]];
		
		[self setOperationError: [self errorWithDescription: [self status] code: 1 andErrorLevel: kQNDownloadOperationErrorRecoverable]];
		[receivedData release];
		receivedData = nil;
		return NO;
	}
	
	
	//parse the returned api answer to get information about the user's account (if it's valid)
	NSString *apiReturn = [[NSString alloc] initWithData: receivedData encoding: NSUTF8StringEncoding];
	[apiReturn autorelease];
	
	NSLog(@"api returned: %@", apiReturn);
	NSString *apiError = [self errorStringForRapidshareErrorPage: apiReturn];
	NSLog(@"api error: %@",apiError);
	
	if (apiError)
	{
		[self setStatus: [NSString stringWithFormat:@"Login Failed: %@", apiError]];
		[self setOperationError: [self errorWithDescription: [self status] code: 1 andErrorLevel: kQNDownloadOperationErrorRecoverable]];
		[receivedData release];
		receivedData = nil;
		return NO;
	}

	//let's extract our login cookie from the response
	//(no that's not a header cookie. it is plain text what you will have to set as a cookie manually.
	// yes rs.com html login system does this shit over javascript ... they are pretty much retards)
	NSString *cookie = [self cookieFromAPIString: apiReturn];
	NSLog(@"cookie: %@", cookie);

	rsCookie = [[NSString alloc] initWithFormat: @"enc=%@", cookie];
	
	[receivedData release];
	receivedData = nil;
	
	return YES; //<-------------------------- check this out ... all below is legacy for RS's old login system before they hired that retarded turkish kid who fucked up everuthing with his javascirpt bullshit
	
	
	
	///////////////////////////////////////////////////////////////////////////
	// Login + Cookie generation
	//////////////////////////////////////////////////////////////////////////
	[self setStatus: @"Logging in"];

	NSString *loginDataString = [NSString stringWithFormat:@"login=%@&password=%@",username,password];
	const char *postData = [loginDataString UTF8String];
	
	curl_easy_setopt(curlHandle, CURLOPT_HTTPPOST,1);
	curl_easy_setopt(curlHandle, CURLOPT_POSTFIELDS, postData);
	curl_easy_setopt(curlHandle, CURLOPT_URL, "https://ssl.rapidshare.com/cgi-bin/premiumzone.cgi");
	curl_easy_setopt(curlHandle, CURLOPT_COOKIEFILE,"/dev/null");
	
	//file writing
	curl_easy_setopt(curlHandle, CURLOPT_WRITEFUNCTION, rapidshare_login_write_data_callback);
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
	
	res = curl_easy_perform(curlHandle);
	NSString *returnString = [[NSString alloc] initWithData: receivedData encoding: NSUTF8StringEncoding];
	[returnString autorelease];
	
	NSLog(@"RS LOGIN returnString: %@",returnString);
	NSString *errorString = [self errorStringForRapidshareErrorPage: returnString];
//	NSLog(@"errorstring: %@",errorString);
	
	[receivedData release];
	receivedData = nil;
	
	printf("RAPIDSHARE LOGIN RETURNED: %i = %s\n",res, curl_easy_strerror(res));
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

- (BOOL) performFileDownload
{
	if (!curlHandle)
	{	
		[self setStatus: @"performFileDownload: No curl handle! Fatal!"];
		[self setOperationError: [self errorWithDescription: [self status] code: 1 andErrorLevel: kQNDownloadOperationErrorDontKnow]];
		return NO;
	}
	
	const char *cookie = [rsCookie cStringUsingEncoding: NSUTF8StringEncoding];
	printf("cookie: %s\n",cookie);
	//setup curl for http get
	curl_easy_setopt(curlHandle, CURLOPT_HTTPGET,1);
	curl_easy_setopt(curlHandle, CURLOPT_URL, [[self URI] UTF8String]);
	curl_easy_setopt(curlHandle, CURLOPT_FOLLOWLOCATION, 1);
	curl_easy_setopt(curlHandle, CURLOPT_COOKIE, cookie);
	
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


#pragma mark check file rs api
/*
 subroutine=checkfiles_v1
 Description:	Gets status details about a list of given files. (files parameter limited to 10000 bytes. filenames parameter limited to 100000 bytes.)
 Parameters:	files=comma separated list of file ids
 filenames=comma separated list of the respective filename. Example: files=50444381,50444382 filenames=test1.rar,test2.rar
 incmd5=if set to 1, field 7 is the hex-md5 of the file. This will double your points! If not given, all md5 values will be 0
 Reply fields:	1:File ID
 2:Filename
 3:Size (in bytes. If size is 0, this file does not exist.)
 4:Server ID
 5:Status integer, which can have the following values:
 0=File not found
 1=File OK (Downloading possible without any logging)
 2=File OK (TrafficShare direct download without any logging)
 3=Server down
 4=File marked as illegal
 5=Anonymous file locked, because it has more than 10 downloads already
 6=File OK (TrafficShare direct download with enabled logging. Read our privacy policy to see what is logged.)
 6:Short host (Use the short host to get the best download mirror: http://rs$serverid$shorthost.rapidshare.com/files/$fileid/$filename)
 7:md5 (See parameter incmd5 in parameter description above.)
 Reply format:	integer,string,integer,integer,integer,string,string
*/
- (BOOL) performRemoteFileCheck
{
	
	LOG_LOCATION();
	
	if (!curlHandle)
		return NO;
	
	NSString *fileid = [[[self URI] pathComponents] objectAtIndex: [[[self URI] pathComponents] count] - 2];
	NSString *filename = [[[self URI] pathComponents] lastObject];
	
	NSString *apiURL = [NSString stringWithFormat: @"https://api.rapidshare.com/cgi-bin/rsapi.cgi?sub=checkfiles_v1&files=%@&filenames=%@",
						   fileid,filename];
	
	///////////////////////////////////////////////////////////////////////////
	// API File Check
	//////////////////////////////////////////////////////////////////////////
	[self setStatus: @"Checking File"];
	
	curl_easy_setopt(curlHandle, CURLOPT_HTTPGET,1);
	curl_easy_setopt(curlHandle, CURLOPT_URL, [apiURL UTF8String]);
	curl_easy_setopt(curlHandle, CURLOPT_FOLLOWLOCATION, 1);
	
	curl_easy_setopt(curlHandle, CURLOPT_WRITEFUNCTION, rapidshare_login_write_data_callback);
	curl_easy_setopt(curlHandle, CURLOPT_WRITEDATA, self);
	
	[receivedData release];
	receivedData = [[NSMutableData alloc] init];
	
	CURLcode res = curl_easy_perform(curlHandle);	//receivedData will contain the api answer
	if (res != CURLE_OK)
	{	
		[self setStatus: [NSString stringWithFormat: @"File Check Failed: %s", curl_easy_strerror(res)]];
		[self setOperationError: [self errorWithDescription: [self status] code: 1 andErrorLevel: kQNDownloadOperationErrorDontKnow]];
		return NO;
	}
	
	NSString *apiReturn = [[NSString alloc] initWithData: receivedData encoding: NSUTF8StringEncoding];
	[apiReturn autorelease];
	
	NSLog(@"file check returned: %@", apiReturn);
	
	[receivedData release];
	receivedData = nil;
	
	
	if ([apiReturn containsString: @"ERROR"])
	{
		NSLog(@"File Check Error: %@",apiReturn);
		[self setStatus: [NSString stringWithFormat: @"File check Error: %@",apiReturn]];
		[self setOperationError: [self errorWithDescription: [self status] code: 1 andErrorLevel: kQNDownloadOperationErrorFatal]];
		return NO;
	}

	NSArray *replyarray = [apiReturn componentsSeparatedByString:@","];
	if (!replyarray || [replyarray count] < 5)
	{
		[self setStatus: [NSString stringWithFormat: @"File check crit Error: Response malformed - could not create array! %@",apiReturn]];
		[self setOperationError: [self errorWithDescription: [self status] code: 1 andErrorLevel: kQNDownloadOperationErrorRecoverable]];
		return NO;
	}
	
	//fourth item in the return is the status of the file @ rapidshare's servers
	NSInteger stat = [[replyarray objectAtIndex: 4] integerValue];
	switch (stat)
	{
		case 0:
			[self setStatus:@"File Check Error: File not found!"];
			[self setOperationError: [self errorWithDescription: [self status] code: 1 andErrorLevel: kQNDownloadOperationErrorFatal]];
			return NO;
			break;
		case 1:
		case 2:
		case 6:
			[self setStatus:@"File OK."];
			return YES;
			break;
		case 3:
			[self setStatus:@"File Check Error: Server Down!"];
			[self setOperationError: [self errorWithDescription: [self status] code: 1 andErrorLevel: kQNDownloadOperationErrorRecoverable]];
			return NO;
			break;
		case 4:
			[self setStatus:@"File Check Error: File marked as illegal!"];
			[self setOperationError: [self errorWithDescription: [self status] code: 1 andErrorLevel: kQNDownloadOperationErrorFatal]];
			return NO;
			break;
		case 5:
			[self setStatus:@"File Check Error: Maximum downloads reached!"];
			[self setOperationError: [self errorWithDescription: [self status] code: 1 andErrorLevel: kQNDownloadOperationErrorFatal]];
			return NO;
			break;
	}
	[self setStatus: [NSString stringWithFormat: @"File Check Error: Uknown File Status: %i",stat]];
	[self setOperationError: [self errorWithDescription: [self status] code: 1 andErrorLevel: kQNDownloadOperationErrorDontKnow]];
	return NO;
}



#pragma mark rapidshare error parser [tm]
- (NSString *) errorStringForRapidshareErrorPage: (NSString *) errorPageHtmlString
{
	//if the api fails us and we get html instead of the requested file
	//we will check for errors manually
	//but we should never get to this
	if ([errorPageHtmlString containsString:@"<!-- E#1 -->"])
		return @"Premium Account not found!";
	if ([errorPageHtmlString containsString:@"<!-- E#4 -->"])
		return @"File not found!";
	if ([errorPageHtmlString containsString:@"<!-- E#5 -->"])
		return @"File has been removed!";
	if ([errorPageHtmlString containsString:@"Free user"])
		return @"Premium Account not valid? Free loader page was returned!";

	//api kram
	if ([errorPageHtmlString containsString:@"ERROR: Login failed."])
		return @"Rapidshare Login Failed!";
	//we need direct downloads ... KEIN BOCK DIE KACK RAPIDSHARE HTML SEITEN FUER DIE DOWNLOAD LINKS ZU PARSIEREN!
	if ([errorPageHtmlString containsString:@"directstart=0"])
		return @"Direct Downloads not enabled! Activate Direct Downloads in the rapidshare.com premium zone settings!";
		
	//check for acc expiration
	NSRange start = [errorPageHtmlString rangeOfString: @"validuntil=" options: NSCaseInsensitiveSearch];
	if (start.location != NSNotFound)
	{
		NSRange srch;
		srch.location = start.location;
		srch.length = 32;
		NSRange end = [errorPageHtmlString rangeOfString: @"\n" options: NSCaseInsensitiveSearch range: srch];
		if (end.location != NSNotFound)
		{
			NSRange rng;
			rng.location = (start.location + start.length);
			rng.length = end.location - (start.location + start.length);
			
			NSString *dateString = [errorPageHtmlString substringWithRange: rng];
			if (dateString)
			{
				NSTimeInterval expirationTimestamp = [dateString doubleValue];
				
				NSDate *now = [NSDate date];
				NSDate *exp = [NSDate dateWithTimeIntervalSince1970: expirationTimestamp];
				
				//NSOrderedDescending = left > right
				//now is greater than exp omfg
				if ([now compare: exp] == NSOrderedDescending)
				{	
					//the user's account has expired
					return @"Account Expired";
				}
			}
		}
	}
	
	
	
	
	return nil;
}
@end
