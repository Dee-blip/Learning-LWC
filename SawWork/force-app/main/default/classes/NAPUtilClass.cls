public class NAPUtilClass {

    public static String getFileSize(Double fileSize)
    {
        /* string representation of a file's size, such as 2 KB, 4.1 MB, etc */
        if (fileSize < 1024)
            return string.valueOf(fileSize) + ' Bytes';
        else if (fileSize >= 1024 && fileSize < (1024*1024))
        {
            //KB
            Decimal kb = Decimal.valueOf(fileSize);
            kb = kb.divide(1024,2);
            return string.valueOf(kb) + ' KB';
        }
        else if (fileSize >= (1024*1024) && fileSize < (1024*1024*1024))
        {
            //MB
            Decimal mb = Decimal.valueOf(fileSize);
            mb = mb.divide((1024*1024),2);
            return string.valueOf(mb) + ' MB';
        }
        else
        {
            // Really? You are going to upload giga byte files?
            Decimal gb = Decimal.valueOf(fileSize);
            gb = gb.divide((1024*1024*1024),2);
            return string.valueOf(gb) + ' GB';
        }   
    }

    public static boolean containsUnsanitaryInputForWWW(String rt)
    {
        String regexForWWW = '(<img|style=|<div)';
        Pattern MyPattern = Pattern.compile(regexForWWW);

        Matcher MyMatcher = MyPattern.matcher(rt);

        return MyMatcher.matches();
    }

    public static List<ContentVersion> getFilesToBeUpdated(List<ContentVersion> cvList)
    {
        List<ContentVersion> cvListToBeUpdated = new List<ContentVersion>();
        for(ContentVersion cvRec : cvList)
        {
            if((!String.isBlank(cvRec.TagCsv) && !cvRec.TagCsv.equals(cvRec.Tag__c)) || (String.isBlank(cvRec.TagCsv) && !String.isBlank(cvRec.Tag__c)))
            {
                cvRec.Tag__c = cvRec.TagCsv;
                cvListToBeUpdated.add(cvRec);
            }
        }
        return cvListToBeUpdated;
    }

    public static Id getLatestVersion(Id cvId)
    { 
        return [select ContentDocument.LatestPublishedVersionId from ContentVersion where Id=:cvId limit 1].ContentDocument.LatestPublishedVersionId;
    }

    public static String getFontAwesomeClassName(String fileExtension)
    {
        Map<String, String> extensionToFontAwesomeMap = new Map<String, String>{
            'pdf' => 'file-pdf-o',
                'txt' => 'file-text-o',
                'docx' => 'file-word-o',
                'pptx' => 'file-powerpoint-o',
                'xlsx' => 'file-excel-o',
                'png' => 'file-image-o',
                'jpeg' => 'file-image-o',
                'jpg' => 'file-image-o',
                'zip' => 'file-archive-o',
                'none' => 'file-o'
        };

        if(extensionToFontAwesomeMap.containsKey(fileExtension))
            return extensionToFontAwesomeMap.get(fileExtension);

        return 'file-o';
    }
}