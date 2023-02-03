// ported from https://github.com/AstinCHOI/Akamai-AuthToken-Java
global class AkamaiEdgeAuthTokenGenerator
{
    webservice static String generateToken(String urlPath, Integer windowInSeconds)
    {

        String expirationTimeStamp = getTokenExpirationTimestamp(windowInSeconds);

        Blob signingKeyBytes = Crypto.generateMac('HmacSHA256',Blob.valueOf('exp='+expirationTimeStamp+'~url='+escapeEarly(urlPath)), EncodingUtil.convertFromHex(NAPSettings.getValue('NetStorageEncryptionKey')));
      
        String signingKey= EncodingUtil.convertToHex(signingKeyBytes);
        String token = 'hdnts=exp='+expirationTimeStamp+'~hmac='+signingKey;
        system.debug(LoggingLevel.error, 'AGH_D' + token);
        return token;
    }


    /*
    public static String generateTokenizedURL(String urlPath, Integer windowInSeconds)
    {
        String expirationTimeStamp = getTokenExpirationTimestamp(windowInSeconds);

        Blob signingKeyBytes = Crypto.generateMac('HmacSHA256',Blob.valueOf('exp='+expirationTimeStamp+'~url='+escapeEarly(urlPath)), EncodingUtil.convertFromHex(NAPSettings.getValue('NetStorageEncryptionKey')));
        String signingKey= EncodingUtil.convertToHex(signingKeyBytes);
        String tok = urlPath+'?hdnts=exp='+expirationTimeStamp+'~hmac='+signingKey;
        system.debug(LoggingLevel.Error, 'AGH_D'+tok);
        return tok;
    }

    */

    public static String escapeEarly(String text)
    {
        try 
        {
            String newText = EncodingUtil.urlEncode(text, 'UTF-8');
            System.Debug(LoggingLevel.Error, 'AGH_D newText'+newText);
            // UGH. Why doesnt apex encode spaces to %20? It encodes it to + for some reason.
            // Also GHOST's URL encoding considers forward slash, question mark, =, & as reserved characters and doesnt encode them
            // The following characters cannot be used in the filenames hence - +, %40, %3D, %26
            newText = newText.replaceAll('%2F', '/').replaceAll('%3F', '?').replaceAll('%40', '@').replaceAll('%3D', '=').replaceAll('%26', '&').replaceAll('%2C', ',').replaceAll('\\+', '%20');
            System.Debug(LoggingLevel.Error, 'AGH_D newText after clean up'+newText);
            return newText;
        } 
        catch (Exception e) 
        {
            System.Debug(LoggingLevel.Error, 'AGH_D exception caught'+e.getStackTraceString() + 'and '+e.getMessage());
            return text;
        }
    }

    public static String getTokenExpirationTimestamp(Integer windowInSeconds)
    {
        Datetime currentTime = Datetime.now();
        Long currentTimeInSeconds = currentTime.getTime()/1000L;
        Long expirationTimeStamp = currentTimeInSeconds + windowInSeconds;
        return String.valueOf(expirationTimeStamp);
    }

}