/*

   @Author - Anand Hegde (ahegde@akamai.com)
   TODO - 

   Sonali Tandon  2nd May 2015 SFDC-941 & SFDC-842 - File browser(Added language and tag filters to content block.)

 */


public class NAPRebrandedPageController
{
    public String pageJSON{get;set;}

    // Using Paej because Page is a reserved word and Paej is phonetically similar to Page
    public class Paej
    {

        private NAP_Page_Builder__c currentPageMenuItem;
        private MainMenuItem currentMainMenuItem;

        private String currentUserFirstName = UserInfo.getFirstName();
        private Boolean isCurrentUserSubscribedToFileLibrary = CurrentUser.isSubscribedToFileLibrary;
    
        private String searchparam;
        private String redirectLocation;
        private String errorMessage ;

        private List<MainMenuItem> mainMenuItems= new List<MainMenuItem>();
        private List<PageMenuItem> pageMenuItems = new List<PageMenuItem>();
        private List<PermanentMenuItem> permanentMenuItems= new List<PermanentMenuItem>();
        private List<SubmenuItem> subMenuItems = new List<SubmenuItem>();
        private transient Map<Id, SubmenuItem> subMenuItemsMap = new Map<Id, SubmenuItem>();
        private transient Map<Id, DetailMenuItem> detailMenuItemsMap = new Map<Id, DetailMenuItem>();
        private transient String mainMenuAutoNameFromURL;
        private transient String errorCode;
        private transient String newsItemId;

        private Set<Id> collectAllContentBlockIds()
        {
            Set<Id> contentIds = new Set<Id>();
            for(SubmenuItem smi : subMenuItems)
            {
                for(ContentBlock icb : smi.contentBlocksInCurrentSubMenu)
                {
                    contentIds.add(icb.Id);
                }
            }
            return contentIds;
        }

        private void addDetailMenuItem(NAP_Page_Builder_Join__c pbj)
        {
            DetailMenuItem dmi= (DetailMenuItem)new DetailMenuItem()
                .withParentSubMenu(pbj.NAP_Page_Builder_Parent__c)
                .withTitle(pbj.NAP_Page_Builder_Child__r.Title__c)
                .withId(pbj.NAP_Page_Builder_Child__c);

            if(this.detailMenuItemsMap.size()==0)
                dmi.activate(true);
            this.detailMenuItemsMap.put(dmi.Id, dmi);

            subMenuItemsMap.get(dmi.parentSubMenuItemId).addDetailMenuItem(dmi);

            if(pbj.NAP_Page_Builder_Child__r.Content_Type__c=='HTML' || pbj.NAP_Page_Builder_Child__r.Content_Type__c=='HTML with Placeholders')
            {
                ContentBlock ithContentBlock = buildContents(pbj.NAP_Page_Builder_Child__r)
                    .withParentSubMenu(pbj.NAP_Page_Builder_Parent__c)
                    .withParentDetailMenu(pbj.NAP_Page_Builder_Child__c)
                    .activate(dmi.isActive);

                subMenuItemsMap.get(ithContentBlock.parentSubMenuId).addContentBlock(ithContentBlock);

            }
        }





        private void addPageMenuItem(NAP_Page_Builder__c menuItem)
        {
            this.pageMenuItems.add((PageMenuItem) new PageMenuItem()
                    .withImage(menuItem.Image__c)
                    .withDescription(menuItem.Description__c)
                    .withTitle(menuItem.Title__c)
                    .withLink(NAPURLService.getLink(menuItem))
                    .withId(menuItem.Id));
        }

        private void addPermanentMenuItem(NAP_Page_Builder__c npb)
        {
            this.permanentMenuItems.add((PermanentMenuItem)new PermanentMenuItem()
                    .withTitle(npb.Title__c)
                    .withLink(npb.Link__c));

            /*

               <BEGIN_RANT>

               Reason for this type casting - 

               Salesforce doesnt allow generics, so I cannot just return a unknown type T like in Java.
               I also cannot override a method with a subtype of the parents return type. (This too
               is allowed in Java.)

               Had it allowed this, I would have done something like this - 

               public abstract class MenuItem
               {
               public MenuItem withTitle(String title)
               {
               this.title = title;
               return getThis;
               }

               public abstract MenuItem getThis();
               }

               public class MainMenuItem
               {
               public override MainMenuItem getThis()
               {
               return this;
               }
               }

               Tihs would have allowed Builder pattern with inheritance with a clean 
               method chaining without the need to type cast to the child type. So I 
               guess the platform doesnt adhere to Liskov substition principle(?)

               <END_RANT>

             */
        }


        private void addMainMenuItem(NAP_Page_Builder__c npb)
        {
            String linq;

            if(NAPWatchman.allows(npb))
                linq = NAPURLService.getLink(npb.Name);
            else
                linq = NAPURLService.getLink(currentPageMenuItem.Id);

            MainMenuItem ithMainMenuItem = (MainMenuItem)new MainMenuItem()
                .makeClickable(NAPWatchman.allows(npb))
                .withTitle(npb.Title__c)
                .withLink(linq)
                .activate(npb.Name.containsIgnoreCase(mainMenuAutoNameFromURL));

            currentMainMenuItem = (currentMainMenuItem==null && ithMainMenuItem.isActive) ? ithMainMenuItem : currentMainMenuItem;

            this.mainMenuItems.add(ithMainMenuItem);
        }


        private void addSubMenuItem(NAP_Page_Builder__c npb)
        {
            SubMenuItem smi = (SubMenuItem)new SubmenuItem(npb.Id).withTitle(npb.title__c);


            if(npb.Content_Type__c=='HTML' || npb.Content_Type__c=='HTML with Placeholders')
            {
                smi.addContentBlock(buildContents(npb));
            }

            if(this.subMenuItemsMap.size()==0)
                smi.activate(true);
            this.subMenuItems.add(smi);
            this.subMenuItemsMap.put(smi.Id, smi);
        }

        private ContentBlock buildContents(NAP_Page_Builder__c npb)
        {
            System.debug('News Item Id :'+newsItemId);
            ContentBlock ithContentBlock = new ContentBlock()
                .withTagFilters(npb.Has_Tag_Filters__c)
                .withLanguageFilters(npb.Has_Language_Filters__c)
                .withId(npb.Id)
                .hasFileBrowser(npb.Is_File_Browser__c)
                .hasNapSearch(npb.Is_Nap_Search__c)
                .hasNewsDisplay(npb.Is_News_Filter__c,npb.id,newsItemId)
                .hasSubscriptionSettings(npb.is_News_Subscription__c)
                .hasLightningComponent(npb)
                .withParentSubMenu(npb.Id)
                .withText(npb.Raw_HTML_Content__c)
                .replacePlaceHolders(npb.Content_Type__c.equalsIgnoreCase('HTML with Placeholders'));


            return ithContentBlock;
        }

        private void addBuildingBlock(NAP_Page_Builder__c npb)
        {
            if(npb.Component_Type__c.equalsIgnoreCase('Main Menu'))
                addMainMenuItem(npb);
            else if(npb.Component_Type__c.equalsIgnoreCase('Permanent Menu'))
                addPermanentMenuItem(npb);
        }



        private Paej()
        {
            Map<String, String> urlParams = System.currentPagereference().getParameters();
            searchparam = ApexPages.currentPage().getParameters().get('str');
            if(String.isBlank(searchparam)){
                searchparam = null;
            }
            System.debug('hell ya'+searchparam);
            mainMenuAutoNameFromURL = urlParams.get('page_id').toUpperCase();
            if (urlParams.get('news_id') != null)
                newsItemId = urlParams.get('news_id').toUpperCase();


            errorCode = urlParams.containsKey('error_code') ? urlParams.get('error_code') : '200';

            if(errorCode=='401')
            {
                errorMessage = NAPSettings.getValue('NAP_No_Access_Error_Message');
            }

            // get current page menu, its main menus and permanent menus
            for(NAP_Page_Builder__c npb : [Select id,Is_News_Filter__c,is_News_Subscription__c, title__c,Component_Type__c, (select nap_page_builder_child__c, nap_page_builder_child__r.Name, nap_page_builder_child__r.Title__c, nap_page_builder_child__r.Link__c,NAP_Page_Builder_Child__r.Component_Type__c, order__c from NAP_Page_Builder_Joins__r order by Order__c) mainAndPermanentMenus from NAP_Page_Builder__c where Id in (select nap_page_builder_parent__c from NAP_Page_Builder_join__c where nap_page_builder_child__r.Name=:mainMenuAutoNameFromURL and nap_page_builder_parent__r.component_type__c='Page')])
            {
                currentPageMenuItem =npb;
            }


            if(currentPageMenuItem!=null)
            {
                // child main menus and permanent menus
                for(NAP_Page_Builder_join__c pbj : currentPageMenuItem.NAP_Page_Builder_Joins__r)
                {
                    addBuildingBlock(pbj.NAP_Page_Builder_Child__r);
                }


                if(currentMainMenuItem.isClickable)
                {
                    // get child sub menus of this current main menu
                    for(NAP_Page_Builder_Join__c pbj : Database.query(new NAPItems().withParentName(mainMenuAutoNameFromURL).withComponentType('Sub Menu').getAll()))
                    {
                        addSubMenuItem(pbj.NAP_Page_Builder_Child__r);
                    }


                    Set<Id> subMenuItemIds = subMenuItemsMap.keySet();
                    // get child detail menus for all submenus
                    for(NAP_Page_Builder_Join__c pbj : Database.query(new NAPItems().withComponentType('Detail Menu').withParentInList('subMenuItemIds').getAll()))
                    {
                        addDetailMenuItem(pbj);
                    }


                    // populate files for all the content blocks
                    for(NAP_File_Filter__c filter : [Select Id, Attribute_Condition__c, Attribute_Filters__c, File_Resource_IDs__c, Tag_Condition__c, Tag_Filter_Long__c, Tag_to_Attribute_Condition__c, NAP_Page_Builder__c, File_Display_Type__c from NAP_File_Filter__c where NAP_Page_Builder__c in :this.collectAllContentBlockIds()])
                    {
                        for(SubmenuItem smi : this.subMenuItems)
                        {
                            for(ContentBlock cb : smi.contentBlocksInCurrentSubMenu)
                            {
                                if(cb.Id.equalsIgnoreCase(filter.NAP_Page_Builder__c))
                                {
                                    cb.withFileFilter(filter)
                                        .setLanguageFiltersAndTagFilter(urlParams.get('lang'), urlParams.get('tag1'));
                                }
                            }
                        }
                    }

                    //get all the page menu items
                    for(NAP_Page_Builder__c  menuItem : [Select Id,Is_News_Filter__c,Title__c,is_News_Subscription__c, Component_Type__c , Component_Order__c,Description__c,Link__c,Image__c from NAP_Page_Builder__c where Component_Type__c ='Page' ORDER BY Component_Order__c ASC ])
                    {
                        addPageMenuItem(menuItem);
                    }
                }
                else
                {
                    redirectLocation = currentMainMenuItem.link;
                }
            }
            else
            {
                redirectLocation = NAPURLService.noSuchPageRedirectLocation;
            }

        }
    }




    private class ContentBlock
    {
        private String richText;
        private Boolean hasDetailMenuParent;
        private String Id;
        private String parentDetailMenuId;
        private String parentSubMenuId;
        private Boolean isActive;
        //SFDC-770
        private Boolean hasFileContent=false;
        private List<FileItem> filesInCurrentContentBlock;
        private NewsSubscriptionWrapper newSettings;
        private LightningComponentWrapper lightningSettings;
        private List<NAPNews.Container> newsItemContainers;
        private String fileDisplayType;
        // SFDC-941 & SFDC-842
        private Boolean hasLanguageFilters; 
        private Boolean hasFileBrowser ;
        
        private Boolean hasTagFilters ;
        //SFDC-1238
        private Boolean hasNapSearch ;
        //private String newsDisplayType;
        private Boolean isNewsFilter;
        private Boolean isIndividualNewsItem;
        private Boolean isNewsSubscriptionSetting;
        private String allNewsPath;

        private Set<String> selectedTags = new Set<String>();
        private Set<String> setOftagFiltersForCurrentBlock;

        private String languageFilter;
        private Set<String> languageFilterOptions ;

        private Boolean isLightningComponent;

        private Set<String> selectedNewsType = new Set<String>();
        private Set<String> newsTypeFilterOptions = new Set<String>();

        private ContentBlock withFileFilter(NAP_File_Filter__c fileFilter)
        {
            this.hasFileContent = true;
            if(String.isBlank(fileFilter.File_Display_Type__c))
            {
                this.fileDisplayType = 'list';
            }
            else
            {
                this.fileDisplayType = fileFilter.File_Display_Type__c.toLowerCase(); 
            }

            if(this.hasTagFilters && !String.isBlank(fileFilter.Tag_Filter_Long__c))
            {
                this.setOftagFiltersForCurrentBlock = new Set<String>();
                List<String> tagFiltersSplit = fileFilter.Tag_Filter_Long__c.split(',');
                tagFiltersSplit.sort();
                for(String tag : tagFiltersSplit)
                {
                    this.setOftagFiltersForCurrentBlock.add(tag.trim());
                }
            }

            System.Debug(LoggingLevel.Error, 'AGH_D withTagFilters after:'+this.setOftagFiltersForCurrentBlock);
            Map<Id,Boolean> mapOfContentDocumentIdToActiveSubscription = new Map<Id,Boolean>();

            //SFDC-770 - rsharma
            List<ContentVersion> cvList = new List<ContentVersion>();
            cvList= NAPFileItems.getFiles(fileFilter,hasFileBrowser);
            System.Debug(LoggingLevel.Error, 'AGH_D cvList'+cvList);
            //SFDC-1201 -  File Subscribe functionality - standon
            if(cvList.size()>0)
            {
                NAPFileSubscribe subscribeInstance= new NAPFileSubscribe(cvList);
                mapOfContentDocumentIdToActiveSubscription = subscribeInstance.getActiveSubscriptionFlags();
            }

            for(ContentVersion cv : cvList)
            {
                FileItem fileItemObj = new FileItem()
                    .withTitle(cv.Display_Title__c).withContentVersionId(cv.Id).withContentDocumentId(cv.ContentDocumentId)
                    .withFileExtension(cv.FileExtension)
                    .withLastModifiedDate(cv.LastModifiedDate)
                    .withFileSize(NAPUtilClass.getFileSize(cv.ContentSize))
                    .withFileLanguage(cv.Language__c)
                    .withFileTags(cv.Tag__c)
                    .withActiveSubscription(mapOfContentDocumentIdToActiveSubscription.get(cv.ContentDocumentId));

                addFileToCurrentContentBlock(fileItemObj);
            }

            if(this.hasTagFilters)
            {
                for(String tag : this.setOftagFiltersForCurrentBlock)
                {
                    Boolean notFound=true;
                    for(ContentVersion cv: cvList)
                    {
                        if(cv.Tag__c.containsIgnoreCase(tag))
                        {
                            notFound=false;
                        }
                    }

                    if(notFound)
                        this.setOftagFiltersForCurrentBlock.remove(tag);

                }
            }
            return this;
        }

        private ContentBlock withLanguageFilters(Boolean hasLanguageFilters)
        {
            this.hasLanguageFilters = hasLanguageFilters;
            return this;

        }


        private ContentBlock withTagFilters(Boolean hasTagFilters)
        {
            this.hasTagFilters = hasTagFilters;
            return this;
        }

        private ContentBlock hasFileBrowser(Boolean hasFileBrowser)
        {
            this.hasFileBrowser = hasFileBrowser;
            return this;

        }
        //sfdc-1238
        private ContentBlock hasNapSearch(Boolean hasNapSearch)
        {
            this.hasNapSearch = hasNapSearch;
            return this;

        }
        private ContentBlock activate(Boolean performActivation)
        {
            this.isActive=false;
            if(performActivation)
                this.isActive = true;
            return this;
        }


        private ContentBlock withParentDetailMenu(String detailMenuId)
        {
            this.parentDetailMenuId = detailMenuId;
            this.hasDetailMenuParent = true;
            return this;
        }

        private ContentBlock withParentSubMenu(String subMenuId)
        {
            this.parentSubMenuId = subMenuId;
            return this;
        }


        private ContentBlock withText(String richText)
        {
            this.richText = richText;
            return this;
        }


        private void addFileToCurrentContentBlock(FileItem fileObjParam)
        {
            if(this.filesInCurrentContentBlock==null)
                this.filesInCurrentContentBlock = new List<FileItem>();

            this.filesInCurrentContentBlock.add(fileObjParam);

            if(hasLanguageFilters)
            {
                if(this.languageFilterOptions==null)
                    this.languageFilterOptions = new Set<String>{'All Languages'};

                this.languageFilterOptions.add(fileObjParam.fileLanguage);
            }
        }

        private ContentBlock withId(Id recordId)
        {
            this.Id=recordId;
            this.hasDetailMenuParent = false;
            return this;
        }

        private ContentBlock hasNewsDisplay(Boolean isNewsFilterParam, String npbId, String newsItemId)
        {
            //this.newsDisplayType = newsDisplayTypeParam;
            this.isNewsFilter = isNewsFilterParam;

            /*if(!String.isBlank(this.newsDisplayType))
            {
                this.newsItemContainers = NAPNews.get('Latest News'.equalsIgnoreCase(newsDisplayType));
                List<Schema.PicklistEntry> pickLists =  NAP_News_Item__c.News_Type__c.getDescribe().getPickListValues();
                for( Schema.PicklistEntry pickList : pickLists)
                {
                    newsTypeFilterOptions.add(pickList.getValue());
                }       
            }*/
            
            if(isNewsFilter)
            {  
                if (newsItemId != null) {
                    this.isIndividualNewsItem = true;
                    //this.allNewsPath = NAPSettings.getValue('News_Page_Builder_Record');
                    this.allNewsPath = '/partners/apex/NAP?page_id='+System.currentPagereference().getParameters().get('page_id').toUpperCase();
                    this.newsItemContainers = NAPNews.getIndividualNews(newsItemId);
                } else {
                    this.isIndividualNewsItem = false;
                    this.newsItemContainers = NAPNews.get(npbId,UserInfo.getUserId());

                    NAP_News_Filter__c newsFilter;
                    List<NAP_News_Filter__c> newsFilters = [Select id,Attribute_Filter__c From NAP_News_Filter__c where NAP_Page_Builder__c=:npbId];
                    if (newsFilters != null &&  newsFilters.size() > 0)
                        newsFilter = newsFilters[0];

                    List<Schema.PicklistEntry> pickLists =  NAP_News_Item__c.News_Type__c.getDescribe().getPickListValues();
                    List<Schema.PicklistEntry> pickListsForEvents =  NAP_News_Item__c.Events_Type__c.getDescribe().getPickListValues();
                    
                    if (newsFilter != null && newsFilter.Attribute_Filter__c.equalsIgnoreCase('Events')) {
                        for( Schema.PicklistEntry pickList : pickListsForEvents)
                        {
                            newsTypeFilterOptions.add(pickList.getValue());
                        }
                    } else {
                        for( Schema.PicklistEntry pickList : pickLists)
                        {
                            newsTypeFilterOptions.add(pickList.getValue());
                        }
                    }
                    
                }     
            }

            return this;
        }

        private ContentBlock hasSubscriptionSettings(Boolean isNewsSettingsParam) {

            this.isNewsSubscriptionSetting = isNewsSettingsParam;

            if (isNewsSubscriptionSetting) {
                System.debug('News Settings :'+getNewsSettings());
                this.newSettings = getNewsSettings();
            }
            return this;
        }

        private ContentBlock hasLightningComponent(NAP_Page_Builder__c npb) {

            this.isLightningComponent = npb.Is_Lightning_Component__c;

            if (isLightningComponent) {
                this.lightningSettings = getLightningComponentSettings(npb);
            }

            return this;

        }

        private ContentBlock replacePlaceHolders(Boolean doReplace)
        {
            if(doReplace)
            {
                if(!String.isBlank(CurrentUser.attributes.get('Partner Account')))
                {
                    this.richText = this.richText.replaceAll('#USERACCOUNT#', CurrentUser.attributes.get('Partner Account').substring(0,15));
                }
                
                if(this.richText.containsIgnoreCase('#USERID#'))
                {
                    this.richText = this.richText.replaceAll('#USERID#', UserInfo.getUserId());
                }

                while (this.richText.containsIgnoreCase('#Video')) 
                {
                    String videoAttributesString = this.richText.substringBetween('#Video=', '#');
                    String[] videoAttributes = videoAttributesString.split(',');
                    System.debug('videoAttributes :'+videoAttributes);
                    String objectHtml = '';

                    if (videoAttributes[0].equalsIgnoreCase('External')) 
                    {
                        objectHtml = '<object data='+videoAttributes[1]+' width='+videoAttributes[3]+' height='+videoAttributes[2] + '>'+
                            '<embed src='+videoAttributes[1] + ' width='+videoAttributes[3]+ ' height='+videoAttributes[2]+'> </embed>'+
                            'Error: Embedded data could not be displayed.'+
                            '</object>';
                        System.debug(LoggingLevel.Error, 'External objectHtml :'+objectHtml);
                    } 
                    else if(videoAttributes[0].equalsIgnoreCase('Internal') || videoAttributes[0].equalsIgnoreCase('NetStorage'))
                    {
                        String internalUrl =  GsmUtilClass.convertToCommunityURL('/apex/NAPVideoPlayer?id='+videoAttributes[1]);

                        System.debug('internalUrl'+internalUrl);
                        objectHtml = '<object data='+internalUrl+' width='+videoAttributes[3]+' height='+videoAttributes[2] + '>'+
                            '<embed src='+videoAttributes[1] + ' width='+videoAttributes[3]+ ' height='+videoAttributes[2]+'> </embed>'+
                            'Error: Embedded data could not be displayed.'+
                            '</object> <br/><p style="text-align:center"><a href="'+internalUrl+'" target="_blank"><font color="#0695d3">View Full Screen</font></a></p>';
                        System.debug(LoggingLevel.Error, 'Internal objectHtml :'+objectHtml);
                    }
                    this.richText = this.richtext.replaceAll('#Video='+videoAttributesString+'#',objectHtml);
                }
            }
            return this;
        }


        private ContentBlock setLanguageFiltersAndTagFilter(String languageParamFromURL, String tagParamsFromURL)
        {
            if(tagParamsFromURL!=null)
            {
                System.Debug(LoggingLevel.Error, 'AGH_D tagParamsFromURL'+tagParamsFromURL+' setOftagFiltersForCurrentBlock: '+ setOftagFiltersForCurrentBlock);

                for (String tag : tagParamsFromURL.split(','))
                {
                    if(setOftagFiltersForCurrentBlock!=null && setOftagFiltersForCurrentBlock.contains(tag.trim()))
                    {
                        this.selectedTags.add(tag.trim());
                    }
                }

            }

            System.Debug(LoggingLevel.Error, 'AGH_D selectedTags:'+selectedTags);

            if(languageParamFromURL!=null && languageFilterOptions.contains(languageParamFromURL))
            {
                languageFilter=languageParamFromURL;
            }
            else
            {
                languageFilter='All Languages';
            }

            return this;

        }



    }

    private abstract class MenuItem
    {
        private String title;
        private String link;
        private Boolean isActive;
        private String Id;

        private MenuItem withTitle(String title)
        {
            this.title = title;
            return this;
        }

        private MenuItem withLink(String link)
        {
            this.link=link;
            return this;
        }

        private MenuItem withId(String Id)
        {
            this.Id = Id;
            this.isActive=false;
            return this;
        }

        private MenuItem activate(Boolean performActivation)
        {
            this.isActive=performActivation;
            return this;
        }
    }


    private class MainMenuItem extends MenuItem
    {
        private Boolean isClickable;
        private MainMenuItem makeClickable(Boolean performAction)
        {
            this.isClickable=performAction;
            return this;

        }
    }

    private class PermanentMenuItem extends MenuItem
    {
        //nothing here yet
    }

    private class DetailMenuItem extends MenuItem
    {
        private String parentSubMenuItemId;

        private DetailMenuItem withParentSubMenu(String parentSubMenuItemId)
        {
            this.parentSubMenuItemId = parentSubMenuItemId;
            return this;
        }
    }

    private class PageMenuItem extends MenuItem
    {
        private String image;
        private String description;

        private PageMenuItem withImage(String fontAwesomeClass)
        {
            this.image = fontAwesomeClass;
            return this;
        }

        private PageMenuItem withDescription(String descr)
        {
            this.description = descr;
            return this;
        }
    }


    private class SubmenuItem extends MenuItem
    {
        private Boolean hasDetailMenus=false;
        private List<DetailMenuItem> detailMenuItemsInCurrentSubMenu;
        private List<ContentBlock> contentBlocksInCurrentSubMenu;

        private void addContentBlock(ContentBlock iCB)
        {
            if(this.contentBlocksInCurrentSubMenu==null)
            {
                this.contentBlocksInCurrentSubMenu = new List<ContentBlock>();
                iCB.isActive = true;
            }

            this.contentBlocksInCurrentSubMenu.add(iCB);
        }

        private void addDetailMenuItem(DetailMenuItem iDM)
        {
            if(this.detailMenuItemsInCurrentSubMenu==null)
                this.detailMenuItemsInCurrentSubMenu = new List<DetailMenuItem>();

            this.detailMenuItemsInCurrentSubMenu.add(iDM);
            this.hasDetailMenus = true;
        }

        private SubmenuItem(Id idParam)
        {
            this.Id=idParam;
        }
    }

    private class FileItem
    {
        private String contentVersionId;
        private String fileName;
        private String fileExtension;
        private String fileSize;
        private String fileDownloadLink;
        private String fileImageLink;
        private String fontAwesomeClass;
        private String lastModifiedDate;
        private String fileLanguage;
        //SFDC-1340
        private Boolean backupactiveSubscription;
        private Boolean activeSubscription;
        private String contentDocumentId;
        private Set<String> fileTags;


        private FileItem withFileTags(String tagCsvField)
        {
            this.fileTags = new Set<String>();
            if(!String.isBlank(tagCsvField))
            {
                this.fileTags.addAll(tagCsvField.toLowerCase().split(','));
            }
            return this;
        }

        private FileItem withFileLanguage(String fileLanguage)
        {
            this.fileLanguage = fileLanguage;
            return this;
        }

        private FileItem withTitle(String fileName)
        {
            this.fileName = fileName;
            return this;
        }

        private FileItem withLastModifiedDate(Datetime lmd)
        {
            this.lastModifiedDate = String.valueOf(date.newinstance(lmd.year(), lmd.month(), lmd.day()));
            return this;
        }

        /** private FileItem withActiveSubscription(Boolean activeSubscription)
          {
          this.activeSubscription = activeSubscription;
          return this;
          }**/

        private FileItem withContentVersionId(String contentVersionId)
        {
            this.contentVersionId = contentVersionId;
            this.fileDownloadLink = GsmUtilClass.convertToCommunityURL(NAPSettings.getValue('File_Download_Link') + contentVersionId + '?operationContext=CHATTER');
            this.fileImageLink = GsmUtilClass.convertToCommunityURL(NAPSettings.getValue('File_Image_Link')+ contentVersionId);
            return this;
        }

        private FileItem withFileExtension(String fileExtension)
        {
            this.fileExtension = String.isBlank(fileExtension) ? 'none' : fileExtension.toUpperCase();
            this.fontAwesomeClass = NAPUtilClass.getFontAwesomeClassName(this.fileExtension);
            return this;
        }

        private FileItem withFileSize(String fileSize)
        {
            this.fileSize = fileSize;
            return this;
        }

        private FileItem withActiveSubscription(Boolean activeSubscription)
        {
            //SFDC-1340
            if(CurrentUser.isSubscribedToFileLibrary)
                this.activeSubscription = activeSubscription || true;
            else
                this.activeSubscription = activeSubscription || false;

            this.backupactiveSubscription = activeSubscription;

            return this;
        }

        private FileItem withContentDocumentId(String contentDocumentId)
        {
            this.contentDocumentId = contentDocumentId;
            return this;
        }

    }

    public class NewsSubscriptionWrapper
    {
        private String name;
        private String email;
        private String type;
        private String EventType;
        private String frequency;
        private Boolean frequencyOverrideWithUrgency = false;
        private Boolean enable = false;
        private Boolean onlyRecieveOTNews = false;
        private List<String> allFrequency;
        private List<String> allNewsTypes;
        private List<String> allEventTypes;
        private Boolean eligibleForOT;

    }

    public class LightningComponentWrapper
    {
        private String lightningComponentName;
        private String lightningFlowname;
        private String arguments;
    }

    public static NewsSubscriptionWrapper getNewsSettings(){

        String userId = UserInfo.getUserId();

        List<NAP_News_Subscription__c> newSettingsList = [Select id,name,Enable_Disable__c,Frequency__c,Only_receive_OT_content_news__c,
                                                            frequency_override__c,Partner_Email__c,Type__c, Event_Types__c, Partner_User__c
                                                         From NAP_News_Subscription__c
                                                         Where Partner_User__c=:userId];

        NewsSubscriptionWrapper wrapper = new NewsSubscriptionWrapper();

        List<String> allFrequency = new List<String>();
        List<String> allNewsTypes = new List<String>();
        List<String> allEventTypes = new List<String>();
        
        List<Schema.PicklistEntry> pleFrequency = NAP_News_Subscription__c.Frequency__c.getDescribe().getPicklistValues();
        List<Schema.PicklistEntry> pleNewTypes = NAP_News_Subscription__c.Type__c.getDescribe().getPicklistValues();
        List<Schema.PicklistEntry> pleEventTypes = NAP_News_Subscription__c.Event_Types__c.getDescribe().getPicklistValues();
            
        for( Schema.PicklistEntry f : pleFrequency)
        {
          allFrequency.add(String.valueOf(f.getValue()));
        }

        for( Schema.PicklistEntry f : pleNewTypes)
        {
          allNewsTypes.add(String.valueOf(f.getValue()));
        }

        for( Schema.PicklistEntry f : pleEventTypes)
        {
          allEventTypes.add(String.valueOf(f.getValue()));
        }

        Boolean OTEligible = false;
        List<User> currentUserList = [Select NAP_Area__c From User where id=:userId];
        if (currentUserList != null && currentUserList.size() > 0) {
            String napArea = currentUserList[0].NAP_Area__c;
            if ((napArea != null && (napArea.equalsIgnoreCase('OTP') || napArea.equalsIgnoreCase('OT'))) && NAPNews.containsOTPPermissionSet(userId))  {
                OTEligible = true;
            }
        }

        Set<String> allNewsTypesSet = new Set<String>();
        allNewsTypesSet.addAll(allNewsTypes);

        Set<String> allEventTypesSet = new Set<String>();
        allEventTypesSet.addAll(allEventTypes);

        if (!OTEligible) {
            allNewsTypesSet.remove('OT');
        }

         allNewsTypes.clear();
         allNewsTypes.addAll(allNewsTypesSet);

         allEventTypes.clear();
         allEventTypes.addAll(allEventTypesSet);


        NAP_News_Subscription__c newsSetting;//check null
        if (newSettingsList != null && newSettingsList.size() > 0) { //News Settings exists for the user
            newsSetting = newSettingsList[0];

            wrapper.name = newsSetting.name;
            wrapper.email = newsSetting.Partner_Email__c;
            wrapper.enable = newsSetting.Enable_Disable__c;
            wrapper.frequency = newsSetting.Frequency__c;
            wrapper.onlyRecieveOTNews = newsSetting.Only_receive_OT_content_news__c;
            wrapper.frequencyOverrideWithUrgency = newsSetting.frequency_override__c;
            wrapper.type = newsSetting.Type__c;
            wrapper.allFrequency = allFrequency;
            wrapper.allNewsTypes = allNewsTypes;
            wrapper.eligibleForOT = OTEligible;
            wrapper.EventType = newsSetting.Event_Types__c;
            wrapper.allEventTypes = allEventTypes;
        } else {
            wrapper.email = UserInfo.getUserEmail();
            wrapper.enable = false;
            wrapper.frequency = '';
            wrapper.onlyRecieveOTNews = false;
            wrapper.frequencyOverrideWithUrgency = false;
            wrapper.type = '';
            wrapper.allFrequency = allFrequency;
            wrapper.allNewsTypes = allNewsTypes;
            wrapper.eligibleForOT = OTEligible;
            wrapper.EventType = '';
            wrapper.allEventTypes = allEventTypes;
        }
         
        return wrapper;
    }

    @RemoteAction
    public static NewsSubscriptionWrapper getNewsSettingsObject(String value){

        NewsSubscriptionWrapper wrapper = getNewsSettings();
        return wrapper;
    }

    public static LightningComponentWrapper getLightningComponentSettings(NAP_Page_Builder__c npb) {

        LightningComponentWrapper wrapper = new LightningComponentWrapper();
        wrapper.lightningComponentName = npb.Lightning_Component_Name__c;
        wrapper.lightningFlowname = npb.Lightning_Flow_Name__c;
        return wrapper;
    }

    @RemoteAction
    public static LightningComponentWrapper getLightningComponentSettingObject(String subMenuId) {

        List<NAP_Page_Builder__c> lightningSubMenuList = [Select id,Lightning_Component_Input__c,Lightning_Component_Name__c,Lightning_Flow_Name__c
                                                             From NAP_Page_Builder__c where id=:subMenuId];
        
        LightningComponentWrapper wrapper = new LightningComponentWrapper();
        if (lightningSubMenuList.size() > 0) {
            wrapper.lightningComponentName = lightningSubMenuList[0].Lightning_Component_Name__c;
            wrapper.lightningFlowname = lightningSubMenuList[0].Lightning_Flow_Name__c;
            wrapper.arguments = JSON.serialize(lightningSubMenuList[0].Lightning_Component_Input__c);
        }                                                     
        return wrapper;
    }

    

    @remoteaction
    public static String saveNewsSubscriptionDetails(String frequency,List<String> newTypes, List<String> eventTypes, Boolean enable,Boolean frequencyUrgencyOverride, Boolean onlyOTNews)
    {
        System.debug('Value of frequency'+frequency);
        String userId = UserInfo.getUserId();

        try {
            List<NAP_News_Subscription__c> newSettingsList = [Select id,name,Enable_Disable__c,Frequency__c,Only_receive_OT_content_news__c,
                                                                frequency_override__c,Partner_Email__c,Type__c, Event_Types__c, Partner_User__c
                                                             From NAP_News_Subscription__c
                                                             Where Partner_User__c=:userId];

            NAP_News_Subscription__c newSettings;

            String newTypesVal = '';
            String newEventTypes = '';

            if (onlyOTNews && newTypes.size() ==0) {
                newTypesVal = 'OT';
            }
            
            for (String s:newTypes) {
                newTypesVal += s + ';';
            }
            newTypesVal = newTypesVal.removeEnd(';');



            if(eventTypes.size() > 0){
                for(String s1 : eventTypes){
                    newEventTypes += s1 + ';';
                }
            }
            newEventTypes = newEventTypes.removeEnd(';');


            //check for null
            if (newSettingsList != null && newSettingsList.size() > 0) { //News Settings exists for the user
                newSettings = newSettingsList[0];
            } else {
                newSettings = new NAP_News_Subscription__c();
                newSettings.Partner_User__c = userId;
                newSettings.name = UserInfo.getFirstName() +' '+ UserInfo.getLastName();
            }
            newSettings.Frequency__c = frequency;
            newSettings.Type__c = newTypesVal;
            newSettings.Event_Types__c = newEventTypes;
            newSettings.Enable_Disable__c = enable;
            newSettings.frequency_override__c = frequencyUrgencyOverride;
            newSettings.Only_receive_OT_content_news__c = onlyOTNews;
            
            upsert newSettings;
            return 'Successfully updated news and events subscription details';
        } catch (Exception e) {
            return 'Error updating news subscription details';
        }
    }

    //SFDC-1201 -  File Subscribe functionality - standon
    @remoteaction
    public static void saveFileSubscriptionDetails(String contentDocumentId, Boolean activeSubscription)
    {
        List<NAP_File_Subscribe__c> listOffileSubscribe = new List<NAP_File_Subscribe__c>();
        System.debug(LoggingLevel.ERROR, contentDocumentId + System.UserInfo.getUserId());
        listOffileSubscribe = [Select Id from NAP_File_Subscribe__c where Content_Document_Id__c =: contentDocumentId AND User__c =: System.UserInfo.getUserId()];

        if(listOffileSubscribe.size() == 0)
        {
            NAP_File_Subscribe__c fileSubscribe = new NAP_File_Subscribe__c(Content_Document_Id__c = contentDocumentId,
                    User__c = System.UserInfo.getUserId());
            if(activeSubscription)
            {
                fileSubscribe.Subscription_Date__c = System.now();
                fileSubscribe.Active_subscription__c = true;
            }
            else
            {
                fileSubscribe.Unsubscribed_Date__c = System.now();
                fileSubscribe.Active_subscription__c = false;

            }

            try {
                insert fileSubscribe;
            }
            catch (Exception e) {
                System.debug('File Subscription failed' + e.getStackTraceString());
            }
        }

        else
        {
            if(activeSubscription)
            {
                listOffileSubscribe[0].Subscription_Date__c = System.now();
                listOffileSubscribe[0].Active_subscription__c = true;
            }
            else
            {
                listOffileSubscribe[0].Unsubscribed_Date__c = System.now();
                listOffileSubscribe[0].Active_subscription__c = false;

            }

            try {
                update  listOffileSubscribe[0];
            }
            catch (Exception e) {
                System.debug('File Subscription failed' + e.getStackTraceString());
            }

        }

    }

    @RemoteAction
    public static List<List<SObject>> search(String searchTerm)
    {
        //NAPCustomSearchPageClass classInstance = new NAPCustomSearchPageClass();
        //List<List<SObject>> searchList = classInstance.search(searchTerm);
        //return searchList;
        return null;
    }
    
    // SFDC-1340
    @RemoteAction
    public static String setLibrarySubscriptionDetails(Boolean subscribeToLibrary)
    {
        Contact contactRecord = new Contact();
        contactRecord.Id = CurrentUser.attributes.get('Contact Id');
        contactRecord.Subscribed_to_Library__c = subscribeToLibrary;
        contactRecord.Validation_Override__c = true;

        try{
            update contactRecord;
        }
        catch(Exception e)
        {
            System.debug('Exception while updating Contact Library Subscription ' + e.getStackTraceString());
        }

        return null;

    }

    public void sendErrorMail()
    {
        if(NAPSettings.getValue('Send_Exception_Mails')=='true' && !String.isBlank(NAPFileItems.exceptionMessage))
        {
            EmailUtils.sendHTMLEmail(NAPSettings.getValue('Exception_Mail_Recipients').split(','), 'NAP Error: File Filter query exception', NAPFileItems.exceptionMessage);
        }

    }

    public NAPRebrandedPageController()
    {
        pageJSON = JSON.serialize(new Paej());
        
        
    
        //System.debug('hell no:'+name);
    }
}