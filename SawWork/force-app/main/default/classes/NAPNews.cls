/*

   Author - AGH - WHY WASN'T THIS NAMED ARNAPNEWS? THE COUNTRY WANTS TO KNOW! I CANT STOP SHOUTING NOW.
*/


public class NAPNews{

    public class Container
    {
        private String containerTitle;//month
        private Datetime intervalStartTime;
        private Datetime intervalEndTime;
        private List<NewsItem> newsItems;
        private String publishStatus;

        public Container(String publishStatusVal)
        {
            this.publishStatus = publishStatusVal;
        }

        public Boolean addNewsItem(NewsItem ni)
        {
            if(newsItems==null)
            {
                if(this.publishStatus.equals('Live'))
                {
                    // group monthly
                    this.intervalStartTime = ni.publishedOn.date().toStartOfMonth();
                    //SFDC-2011
                    //this.intervalEndTime = Datetime.newInstance(ni.publishedOn.year(), ni.publishedOn.month()+1, 1, 00, 00, 00);
                    this.intervalEndTime = ni.publishedOn.date().toStartOfMonth().addMonths(1);
                    this.containerTitle = ni.publishedOn.format('MMMMM yyyy');
                }
                else
                {
                    // group yearly
                    this.intervalStartTime = Datetime.newInstance(ni.publishedOn.year(), 1, 1);
                    this.intervalEndTime = Datetime.newInstance(ni.publishedOn.year()+1, 1, 1);
                    this.containerTitle = ni.publishedOn.format('yyyy');
                }
                newsItems = new List<NewsItem>();

            }

            //SFDC-2011
            Date newPublishedDate = ni.publishedOn.date();
            if((intervalStartTime <= newPublishedDate) && (newPublishedDate < intervalEndTime))
            {
                newsItems.add(ni);
                return true;
            }
            return false;
        }
    }

    public class NewsItem
    {
        private String title;
        private DateTime publishedOn;
        private String richTextContent;
        private String publishStatus;
        private List<NewsItemLink> links = new List<NewsItemLink>();
        private Boolean accordionControl;
        private String newsType;
        private String itemType;
        private String eventsType;
        private String formattedDate;
        private String name1;

        public NewsItem(NAP_News_Item__c ni)
        {
            this.title = ni.Title__c;
            // Commenting as part of SFDC-1881
             // this.publishedOn = Datetime.valueOfGmt(ni.Published_On__c.format('YYYY-MM-dd HH:mm:ss')) ;
              this.publishedOn = Datetime.valueOf(ni.Published_On__c.format('YYYY-MM-dd HH:mm:ss')) ;

            this.richTextContent = ni.RAW_HTML__c;
            this.publishStatus = ni.Publish_Status__c;
            this.newsType = ni.News_Type__c;
            this.itemType = ni.Item_Type__c;
            this.eventsType = ni.Events_Type__c;
            this.formattedDate= this.publishedOn.format('MMMMM dd');
            this.name1 = ni.name;

            for(NAP_News_Item_Link__c nnil : ni.NAP_News_Item_Links__r)
            {
                this.links.add(new NewsItemLink(nnil.Link_Display_Text__c, nnil.Link__c));
            }
        }


    }

    public class NewsItemLink
    {
        private String displayText;
        private String linkDestination;

        public NewsItemLink(String displayTextParam, String linkDestinationParam)
        {
            this.displayText = displayTextParam;
            this.linkDestination = linkDestinationParam;
        }
    }

    public static List<NAPNews.Container> get(String npbId,String userId)
    {
        Boolean validOTPUser = false;
        List<NAPNews.Container> newsContainers ;// SDFC 7172


        if(npbId==null) return newsContainers; //SDFC 7172
        //return null;

        List<NAP_News_Filter__c> newsFilter = [Select id,Attribute_Filter__c,Attribute_Condition__c, Publish_Status__c 
                                        From NAP_News_Filter__c 
                                        Where NAP_Page_Builder__c=:npbId
                                        Order By createdDate Desc];

        if (newsFilter.size() == 0) return newsContainers; //SDFC 7172
        // return null;

        //Publish status can Live, Draft, Archive
        String publishStatus = newsFilter[0].Publish_Status__c;
        if (newsFilter[0].Publish_Status__c == null || newsFilter[0].Publish_Status__c == '')
            return newsContainers; // SDFC 7172
            //return null;

        //Attribute filters to show new on the UI - News, events, OTP
        String attributes = newsFilter[0].Attribute_Filter__c;
        String condition = newsFilter[0].Attribute_Condition__c;

        List<String> attributesValuesList = attributes.split(';');
        Set<String> attributesValues = new Set<String>();
        attributesValues.addAll(attributesValuesList);

        User user = [Select id,NAP_Area__c From user where id=:userId];
        if (user == null) return newsContainers; // SDFC 7172
        //return null;


        if (attributesValues.contains('OTP')) {
            //check whether the User is enabled to OTP content
            if (user.NAP_Area__c != null && user.NAP_Area__c.equalsIgnoreCase('OTP') && containsOTPPermissionSet(userId)) {
                System.debug('Valid OTP User');
                validOTPUser = true;
            } else {
                System.debug('Invalid OTP User');
                return newsContainers; // SDFC 7172
                //return null;
            }
        } 

        newsContainers = new List<NAPNews.Container>();
        Container currentNewsContainer = new Container(publishStatus);
        //isLatestNews? 'Live':'Archive'
        for(NAP_News_Item__c ni : getNewsRecords(attributesValues,publishStatus,validOTPUser))
        {
            if ((attributesValues.contains('OTP') || attributesValues.contains('OT')) && ni.Attribute__c != null && ni.Attribute__c.equalsIgnoreCase('User Type') && ni.Attribute_Value__c != null && ni.Attribute_Value__c.equalsIgnoreCase('OTP')) 
            {
                NewsItem ithNewsItem = new NewsItem(ni);

                if(!currentNewsContainer.addNewsItem(ithNewsItem))
                {
                    //cant add in current, get a new one and add
                    newsContainers.add(currentNewsContainer);
                    currentNewsContainer = new Container(publishStatus);
                    currentNewsContainer.addNewsItem(ithNewsItem);
                }
            } else if ((ni.Attribute__c == null || !ni.Attribute__c.equalsIgnoreCase('User Type')) && (ni.Attribute_Value__c == null || !ni.Attribute_Value__c.equalsIgnoreCase('OTP'))) {
                NewsItem ithNewsItem = new NewsItem(ni);

                if(!currentNewsContainer.addNewsItem(ithNewsItem))
                {
                    //cant add in current, get a new one and add
                    newsContainers.add(currentNewsContainer);
                    currentNewsContainer = new Container(publishStatus);
                    currentNewsContainer.addNewsItem(ithNewsItem);
                }
            }
        }

        newsContainers.add(currentNewsContainer);

        return newsContainers;
        //return null; SDFC 7172
    }

    public static List<NAP_News_Item__c> getNewsRecords(Set<String> newsType, String publishedStatus, Boolean validOTPUserVal)
    {
        
        List<NAP_News_Item__c> napNewsEmptyArray = new List<NAP_News_Item__c>();
        if (newsType==null || newsType.size()==0) return napNewsEmptyArray;

        Integer monthLimit = NAPSettings.getInt('NumberOfMonthsOfLatestNews');
        if(publishedStatus.equals('Archive'))
            monthLimit = NAPSettings.getInt('NumberOfMonthsOfArchivedNews');

        Datetime threshold = Datetime.now().addMonths(-monthLimit);
        Integer maxNewsItemsLimit = NAPSettings.getInt('MaxNewsItems');

        Set<String> publishTypes = new Set<String>();

        //if (newsType.contains('New')) {
        //    publishTypes.add('Live');
        //}
        //if (newsType.contains('Events')) {
        //    publishTypes.add('Events');
        //}
        //if (newsType.contains('Archive')) {
        //    publishTypes.add('Archive');
        //} else if (newsType.size() == 1 && newsType.contains('OTP')) {
        //    publishTypes.add('Live');
        //    publishTypes.add('Archive');
        //}
        System.debug('newsType :'+newsType);
        System.debug('Published type :'+publishedStatus);

        if (!validOTPUserVal) {
            return [select Published_On__c,Name, Publish_Status__c,Events_Type__c,Item_Type__c, RAW_HTML__c, Title__c, News_Type__c,Attribute__c,Attribute_Value__c,
                    (select Link__c, Link_Display_Text__c from NAP_News_Item_Links__r Order by Order__c asc) 
                 from NAP_News_Item__c 
                 where Item_Type__c IN:newsType and Publish_Status__c =:publishedStatus and Published_On__c>=:threshold and Published_On__c<=TODAY 
                 order by Published_On__c desc limit 500];
        } else {
            return [select Published_On__c,Name,Item_Type__c, Publish_Status__c, Events_Type__c, RAW_HTML__c, Title__c, News_Type__c,Attribute__c,Attribute_Value__c,
                    (select Link__c, Link_Display_Text__c from NAP_News_Item_Links__r Order by Order__c asc) 
                 from NAP_News_Item__c 
                 where Item_Type__c = 'News' and Publish_Status__c =:publishedStatus and Published_On__c>=:threshold and Published_On__c<=TODAY and Attribute__c='User Type' and Attribute_Value__c='OTP' 
                 order by Published_On__c desc limit 500];
        }
    }

    public static List<NAPNews.Container> getIndividualNews(String newsId) {

        List<NAPNews.Container> newsContainerList ; //SDFC 7172

        if (newsId==null) return newsContainerList; //SDFC 7172
        //return null;

        List<NAP_News_Item__c> news = [select Name,Published_On__c,Item_Type__c,Events_Type__c, Publish_Status__c, RAW_HTML__c, Title__c, News_Type__c,
                                            (select Link__c, Link_Display_Text__c from NAP_News_Item_Links__r) 
                                         from NAP_News_Item__c 
                                         where Name =:newsId];

        if (news.size()==0) return newsContainerList; // SDFC 7172
        //return null;

        //Set<String> attributes = new Set<String>();
        //attributes.add('New');
        String publishStatus = news[0].Publish_Status__c;

        Container newsContainer = new Container(publishStatus);
        NewsItem newItem = new NewsItem(news[0]);
        newsContainer.addNewsItem(newItem);

        newsContainerList = new List<NAPNews.Container>();
        newsContainerList.add(newsContainer);

        return newsContainerList;
    }

    public static Boolean containsOTPPermissionSet(String userId) {

        Boolean user_has_permission = false;
        //directly query permission set rather than iterating
        List<PermissionSetAssignment> currentUserPerSet = [select Assignee.Name, PermissionSet.Name 
                                                            from PermissionSetAssignment
                                                            where Assignee.Id = :userId];
        for ( PermissionSetAssignment psa : currentUserPerSet ) {
            System.debug('##psa.PermissionSet.Name' + psa.PermissionSet.Name);
            if ( psa.PermissionSet.Name.equals('OTP') ) {
                user_has_permission = true;
            }
        }
        return user_has_permission;
    }

}