public with sharing class RevRecAppSettingController {

    //Class variables
    RevRecAppSetting__c theSetting;
    Map<String, String> allDates = new Map<String, String>();
    Set<String> allOpportunityTypes = new Set<String>();
    Map<String, String> allOpportunityStages = new Map<String, String>();
    Map<String, String> allOpportunityRecordType = new Map<String, String>();
    
    public List<String> leftStartSelected {get; set;}
    public List<String> rightStartSelected {get; set;}
    public List<String> leftEndSelected {get; set;}
    public List<String> rightEndSelected {get; set;}
    
    public List<String> leftOpportunityStageSelected {get; set;}
    public List<String> rightOpportunityStageSelected {get; set;}
    public List<String> leftOpportunityTypeSelected {get; set;}
    public List<String> rightOpportunityTypeSelected {get; set;}
    public List<String> leftOpportunityRecordTypeSelected {get; set;}
    public List<String> rightOpportunityRecordTypeSelected {get; set;}
    
    public Boolean showRecordTypeSection {get;set;}
    
    Map<String, String> leftStartDates = new Map<String, String>();
    Map<String, String> rightStartDates = new Map<String, String>();
    Map<String, String> leftEndDates = new Map<String, String>();
    Map<String, String> rightEndDates = new Map<String, String>();
    
    Map<String, String> leftOpportunityStages = new Map<String, String>();
    Map<String, String> rightOpportunityStages = new Map<String, String>();
    Map<String, String> leftOpportunityRecordType = new Map<String, String>();
    Map<String, String> rightOpportunityRecordType = new Map<String, String>();
    Set<String> leftOpportunityTypes = new Set<String>();
    Set<String> rightOpportunityTypes = new Set<String>();
    
    boolean showDateOfMonth = false;
    boolean showCertainWeekDay = false;
    boolean showDateOfMonthTr = false;
    boolean showCertainWeekDayTr = false;
    public Boolean showChartPreference = false;
    
    //Map is used to hold the field permission
    Static Map<String, Schema.DescribeFieldResult> mapfieldAppSetResult = Utility.getFieldPermissions('RevRecAppSetting__c');
    
    // Constructor
    public RevRecAppSettingController () {
        init(); 
    }
    
    public  RevRecAppSetting__c  AppSettings {
        get { return theSetting;}
    } 
    
    public void init() {
        string accessible = RevRecHelper.HasUserLevelAccessForREVview();
        if (accessible.length() > 0){
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.Fatal, 'Insufficient access:' + accessible));
            return;                                                
        }
        List<RevRecAppSetting__c> theSettingList = [Select Id, Is_Closed_Date_Validation__c, Name, Opportunity_Record_Type__c, 
        											Opportunity_Stage__c, Opportunity_Type__c,  Selected_Start_Date_Types__c, Selected_End_Date_Types__c, 
        											Time_of_Month_Selection_Types__c, Time_of_Month_Selection_Types_tr__c,  Certain_date_of_month__c, 
        											Certain_date_of_month_tr__c, Certain_weekday__c, Certain_weekday_tr__c,Certain_weekday_day__c,
        											 Certain_weekday_day_tr__c, Certain_days_before_last_weekday__c, Certain_days_before_last_weekday_tr__c, 
        											 Certain_days_before_last_weekday_day__c, Certain_days_before_last_weekday_day_tr__c, DiagnosticsEnabled__c, 
                                                     Validate_Amortized_Milestones_Against_Li__c, Chart_Pref__c FROM  RevRecAppSetting__c  WHERE Name='AppSetting' LIMIT 1 ];
                                                   
        if (theSettingList.Size() == 0 ) {
            theSetting = new RevRecAppSetting__c(Name='AppSetting', 
                                                Time_of_Month_Selection_Types__c = '1' ,
                                                Time_of_Month_Selection_Types_tr__c = '1' ,
                                                Validate_Amortized_Milestones_Against_Li__c = true,
                                                Chart_Pref__c = '1'
                                                );
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.Info, 'Please click "Application Settings" tab to start'));                                                
            //insert theSetting;
        } else {
            theSetting = theSettingList[0];
            if(Utility.checkFieldPermission(mapfieldAppSetResult,'Chart_Pref__c',Constants.PERMISSION_UPSERT)){
                if(String.isBlank(theSetting.Chart_Pref__c)) 
                    theSetting.Chart_Pref__c = '1';
            }
        }       
        
        //theSetting.Validate_Amortized_Milestones_Against_Li__c = true;
        
        leftStartSelected  = new List<String>();
        rightStartSelected = new List<String>();
        leftEndSelected = new List<String>();
        rightEndSelected = new List<String>();
        
        showRecordTypeSection = false;
        
        if (!Schema.SObjectType.Opportunity.isAccessible() || !Schema.SObjectType.OpportunityLineItem.isAccessible() ) {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.Fatal, 'Insufficient access'));
            return;                                                
        }
        
        allDates = RevRecHelper.getAllOpportunityFieldsWithDateType();
        
        if (theSetting.Selected_Start_Date_Types__c != null) {
            List<String> tempList = theSetting.Selected_Start_Date_Types__c.split(',');
            for(String s: tempList) {
                if (allDates.containsKey(s))
                    rightStartDates.put(s,allDates.get(s) );
            }
        }
        
        if (theSetting.Selected_End_Date_Types__c != null) {
            List<String> tempList = theSetting.Selected_End_Date_Types__c.split(',');
            for(String s: tempList) {
                if (allDates.containsKey(s))
                    rightEndDates.put(s, allDates.get(s));
            }
        }

        for(String s : allDates.keySet()) {
            if (!rightStartDates.containsKey(s)) leftStartDates.put(s,  allDates.get(s));
            if (!rightEndDates.containsKey(s)) leftEndDates.put(s,  allDates.get(s));
        }           
    
        if (theSetting.Time_of_Month_Selection_Types__c == '2')
            showDateOfMonth = true;
        else if (theSetting.Time_of_Month_Selection_Types__c  == '3')
            showCertainWeekDay = true;
            
        if (theSetting.Time_of_Month_Selection_Types_tr__c == '2')
            showDateOfMonthTr = true;
        else if (theSetting.Time_of_Month_Selection_Types_tr__c  == '3')
            showCertainWeekDayTr = true;

        leftOpportunityStageSelected = new List<String>();
        rightOpportunityStageSelected = new List<String>();
        leftOpportunityTypeSelected = new List<String>();
        rightOpportunityTypeSelected = new List<String>();
        leftOpportunityRecordTypeSelected = new List<String>();
        rightOpportunityRecordTypeSelected = new List<String>();
        
        allOpportunityTypes = getOpportunityTypes();
        
        Set<Schema.PicklistEntry> setOpportunityTypes = new Set<Schema.PicklistEntry>();
        setOpportunityTypes.addAll(Schema.getGlobalDescribe().get('Opportunity').getDescribe().fields.getMap().get('Type').getDescribe().getPickListValues());
        
        if (theSetting.Opportunity_Type__c != null) {
            List<String> tempList = theSetting.Opportunity_Type__c.split(',');
            for(String s: tempList) {
            	for(Schema.PicklistEntry typeValues : setOpportunityTypes) {
            		if(typeValues.getLabel() == s && typeValues.isActive()) 
                		rightOpportunityTypes.add(s);	
            	}
            }
        }
        for(String s : allOpportunityTypes) {
            if (!rightOpportunityTypes.contains(s)) leftOpportunityTypes.add(s);
        }     
                     
        allOpportunityStages = getOpportunityStages();
        if (theSetting.Opportunity_Stage__c != null) {
            List<String> tempList = theSetting.Opportunity_Stage__c.split(',');
            for(String s: tempList) {
                if (allOpportunityStages.containsKey(s)){
                    rightOpportunityStages.put(s, allOpportunityStages.get(s));
                }
            }
        }
        for(String s : allOpportunityStages.keySet()) {
            if (!rightOpportunityStages.containsKey(s)) leftOpportunityStages.put(s, allOpportunityStages.get(s));
        } 
        
        //Code is added on 09/15/2016
        //Enhancement Opportunity Record Type support
        //Method call to get all record
        allOpportunityRecordType = getOpportunityRecordType();
        
        //Check if record type is found
        if(showRecordTypeSection &&  allOpportunityRecordType != null) {
            
            if (theSetting.Opportunity_Record_Type__c != null) {
                List<String> tempList = theSetting.Opportunity_Record_Type__c.split(',');
                for(String s: tempList) {
                    if (allOpportunityRecordType.containsKey(s)){
                        rightOpportunityRecordType.put(s, allOpportunityRecordType.get(s));
                    }
                }
            }
            for(String s : allOpportunityRecordType.keySet()) {
                if (!rightOpportunityRecordType.containsKey(s)) leftOpportunityRecordType.put(s, allOpportunityRecordType.get(s));
            }
        }
        
    } 

    public List<SelectOption> getSelectedStartDate() {
        List<SelectOption> options = new List<SelectOption>();
        for(string s: rightStartDates.keySet())
            options.add(new SelectOption(s, rightStartDates.get(s)));
        return options;
    }
    
    public List<SelectOption> getUnSelectedStartDate() {
        List<SelectOption> options = new List<SelectOption>();
        for(string s: leftStartDates.keySet())
            options.add(new SelectOption(s,leftStartDates.get(s)));
        return options;
    }

    public List<SelectOption> getSelectedEndDate() {
        List<SelectOption> options = new List<SelectOption>();
        for(string s: rightEndDates.keySet())
            options.add(new SelectOption(s,rightEndDates.get(s)));
        return options;
    }
    
    public List<SelectOption> getUnSelectedEndDate() {
        List<SelectOption> options = new List<SelectOption>();
        for(string s: leftEndDates.keySet())
            options.add(new SelectOption(s,leftEndDates.get(s)));
        return options;
    }

    public List<SelectOption> getSelectedOpportunityType() {
        List<SelectOption> options = new List<SelectOption>();
        for(string s: rightOpportunityTypes)
            options.add(new SelectOption(s,s));
        return options;
    }
    
    public List<SelectOption> getUnSelectedOpportunityType() {
        List<SelectOption> options = new List<SelectOption>();
        for(string s: leftOpportunityTypes)
            options.add(new SelectOption(s,s));
        return options;
    }
        
    public List<SelectOption> getSelectedOpportunityStage() {
        List<SelectOption> options = new List<SelectOption>();
        for(string s: rightOpportunityStages.keySet()){
            options.add(new SelectOption(s,rightOpportunityStages.get(s)));
        }
        return options;
    }
    
    public List<SelectOption> getUnSelectedOpportunityStage() {
        List<SelectOption> options = new List<SelectOption>();
        for(string s: leftOpportunityStages.keySet())
            options.add(new SelectOption(s,leftOpportunityStages.get(s)));
        return options;
    }
    
    public List<SelectOption> getSelectedOpportunityRecordType() {
        List<SelectOption> options = new List<SelectOption>();
        for(string s: rightOpportunityRecordType.keySet()){
            options.add(new SelectOption(s,rightOpportunityRecordType.get(s)));
        }
        return options;
    }
    
    public List<SelectOption> getUnSelectedOpportunityRecordType() {
        List<SelectOption> options = new List<SelectOption>();
        for(string s: leftOpportunityRecordType.keySet())
            options.add(new SelectOption(s,leftOpportunityRecordType.get(s)));
        return options;
    }

    public PageReference StartSelectClick() {
        rightStartSelected.clear();
        for(string s: leftStartSelected) {
            if (allDates.containsKey(s)) {
                rightStartDates.put(s, allDates.get(s));
                leftStartDates.remove(s);
            }
        }
        return null;
    }

    public PageReference StartUnSelectClick() {
        leftStartSelected.clear();
        for(string s: rightStartSelected) {
            if (allDates.containsKey(s)) {
                rightStartDates.remove(s);
                leftStartDates.put(s, allDates.get(s));
            }
        }
        return null;
    }
    
    public PageReference EndSelectClick() {
        rightEndSelected.clear();
        for(string s: leftEndSelected) {
            if (allDates.containsKey(s)) {
                rightEndDates.put(s, allDates.get(s));
                leftEndDates.remove(s);
            }
        }
        return null;
    }

    public PageReference EndUnSelectClick() {
        leftEndSelected.clear();
        for(string s: rightEndSelected) {
            if (allDates.containsKey(s)) {
                rightEndDates.remove(s);
                leftEndDates.put(s,allDates.get(s));
            }
        }
        return null;
    }

    public PageReference OpportunityTypeSelectClick() {
        rightOpportunityTypeSelected.clear();
        for(string s: leftOpportunityTypeSelected) {
            rightOpportunityTypes.add(s);
            leftOpportunityTypes.remove(s);
        }
        return null;
    }

    public PageReference OpportunityTypeUnSelectClick() {
        leftOpportunityTypeSelected.clear();
        for(string s: rightOpportunityTypeSelected) {
            rightOpportunityTypes.remove(s);
            leftOpportunityTypes.add(s);
        }
        return null;
    }

    public PageReference OpportunityStageSelectClick() {
        rightOpportunityStageSelected.clear();
        for(string s: leftOpportunityStageSelected) {
            if (allOpportunityStages.containsKey(s)) {
                rightOpportunityStages.put(s, allOpportunityStages.get(s));
                leftOpportunityStages.remove(s);
            }
        }
        return null;
    }

    public PageReference OpportunityStageUnSelectClick() {
        leftOpportunityStageSelected.clear();
        for(string s: rightOpportunityStageSelected) {
            if (allOpportunityStages.containsKey(s)) {
                leftOpportunityStages.put(s, allOpportunityStages.get(s));
                rightOpportunityStages.remove(s);
            }
        }
        return null;
    }
    
     public PageReference OpportunityRecordTypeSelectClick() {
        rightOpportunityRecordTypeSelected.clear();
        for(string s: leftOpportunityRecordTypeSelected) {
            if (allOpportunityRecordType.containsKey(s)) {
                rightOpportunityRecordType.put(s, allOpportunityRecordType.get(s));
                leftOpportunityRecordType.remove(s);
            }
        }
        return null;
    }

    public PageReference OpportunityRecordTypeUnSelectClick() {
        leftOpportunityRecordTypeSelected.clear();
        for(string s: rightOpportunityRecordTypeSelected) {
            if (allOpportunityRecordType.containsKey(s)) {
                leftOpportunityRecordType.put(s, allOpportunityRecordType.get(s));
                rightOpportunityRecordType.remove(s);
            }
        }
        return null;
    }

    public Boolean getShowDateOfMonth () { return showDateOfMonth;}
    public void setShowDateOfMonth (Boolean theValue) {showDateOfMonth = theValue; }

    public Boolean getShowCertainWeekDay () { return showCertainWeekDay;}
    public void setShowCertainWeekDay (Boolean theValue) {showCertainWeekDay = theValue; }

    public Boolean getShowDateOfMonthTr () { return showDateOfMonthTr;}
    public void setShowDateOfMonthTr (Boolean theValue) {showDateOfMonthTr = theValue; }

    public Boolean getShowCertainWeekDayTr () { return showCertainWeekDayTr;}
    public void setShowCertainWeekDayTr (Boolean theValue) {showCertainWeekDayTr = theValue; }

    public PageReference TimeOfMonthSelectionTypes() {
        System.debug('TimeOfMonthSelectionTypes is called and the value is :' + theSetting.Time_of_Month_Selection_Types__c);
        showDateOfMonth = false;
        showCertainWeekDay = false;
        if (theSetting.Time_of_Month_Selection_Types__c == '2')
            showDateOfMonth = true;
        else if (theSetting.Time_of_Month_Selection_Types__c  == '3')
            showCertainWeekDay = true;
            
        return null;

    }

    public PageReference TimeOfMonthSelectionTypesTr() {
        showDateOfMonthTr = false;
        showCertainWeekDayTr = false;
        if (theSetting.Time_of_Month_Selection_Types_tr__c == '2')
            showDateOfMonthTr = true;
        else if (theSetting.Time_of_Month_Selection_Types_tr__c  == '3')
            showCertainWeekDayTr = true;
            
        return null;

    }

    public PageReference cancel() {        return null;    } 
    public PageReference save() { 
        if (!Schema.sObjectType.RevRecAppSetting__c.isUpdateable() || !Schema.sObjectType.RevRecAppSetting__c.isCreateable()){
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.Fatal, 'Insufficient access'));
            return null;                                                
        }
        
        string selectedStartDateFields = '';
        string selectedEndDateFields = '';
        
        for(string item : rightStartDates.keySet()) {
            if (selectedStartDateFields.length() != 0)
                selectedStartDateFields = selectedStartDateFields + ',';
            selectedStartDateFields = selectedStartDateFields + item;               
        }
        for(string item : rightEndDates.keySet()) {
            if (selectedEndDateFields.length() != 0)
                selectedEndDateFields = selectedEndDateFields + ',';
            selectedEndDateFields = selectedEndDateFields + item;               
        }
        AppSettings.Selected_Start_Date_Types__c = selectedStartDateFields;
        Appsettings.Selected_End_Date_Types__c = selectedEndDateFields;
        
        string selectedOpportunityTypeFields = '';
        for(string item : rightOpportunityTypes) {
            if (selectedOpportunityTypeFields.length() != 0)
                selectedOpportunityTypeFields = selectedOpportunityTypeFields + ',';
            selectedOpportunityTypeFields = selectedOpportunityTypeFields + item;               
        }
        AppSettings.Opportunity_Type__c = selectedOpportunityTypeFields;
  
        string selectedOpportunityStageFields = '';    
        set<string> oppStageIds = rightOpportunityStages.keySet();  
        for(string item : oppStageIds) {
            if (selectedOpportunityStageFields.length() != 0)
                selectedOpportunityStageFields = selectedOpportunityStageFields + ',';
            selectedOpportunityStageFields = selectedOpportunityStageFields + item;             
        }
        Appsettings.Opportunity_Stage__c = selectedOpportunityStageFields;
        
        String selectedOpportunityRecordTypeFields = '';    
        Set<String> oppRecordTypeIds = rightOpportunityRecordType.keySet();  
        for(String item : oppRecordTypeIds) {
            if(selectedOpportunityRecordTypeFields.length() != 0)
                selectedOpportunityRecordTypeFields = selectedOpportunityRecordTypeFields + ',';
            selectedOpportunityRecordTypeFields = selectedOpportunityRecordTypeFields + item;             
        }
        Appsettings.Opportunity_Record_Type__c = selectedOpportunityRecordTypeFields;
        
        if(Utility.checkObjectPermission(Constants.PERMISSION_UPSERT, 'RevRecAppSetting__c'))
            upsert(theSetting);
        
        Pagereference pg ;
		 if(Utility.getUITheme().contains('Theme4')) 
		   pg = Page.RevRecConfig_Clone; 
		 else
		 	pg = Page.RevRecConfig;
         
        return  pg;    
    }
    
    public List<SelectOption> getMonthDaySelectOptions() {
        List<SelectOption> options = new List<SelectOption>();
        for(Integer i = 1; i < 29; i++)
            options.add(new SelectOption(String.valueof(i), String.valueOf(i)));
        return options;
    }
      
    public Map<String, String> getOpportunityStages() {
        if (!Schema.sObjectType.OpportunityStage.fields.Description.isAccessible()){
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.Info, 'User has no access to OpportunityStage object'));
            return null;                                                
        }

        Map<String, String> allStages = new Map<String, String>();
        List<OpportunityStage> theList = [select Id, Description, MasterLabel, isActive FROM  OpportunityStage WHERE isActive = true LIMIT 100];
        for(OpportunityStage item: theList){
            allStages.put(item.Id, item.MasterLabel);
        }
        return allStages;
    }
    
    //Code is added on 09/15/2016
    //Enhancement Opportunity Record Type support
    //Method to get all available record type
    public Map<String, String> getOpportunityRecordType() {
        
        //Map of record type name and record type
        //Map<String, String> allRecordType = new Map<String, String>();
        
        //---------------------------------
        String query = 'SELECT Id, Name, ';
        Map<String, String> activeRecordTypes = new Map<String, String>();
       
        //List to hold the Record type values that are active
        List<RecordType> activeRT = new List<RecordType>();
        
        //Set to hold record type id's
        Set<Id> recordTypeIds = new Set<Id>();
        
        //Fecthing all record type for opportunity
        Map<String, Schema.RecordTypeInfo> mapNameWithRecordType = Schema.getGlobalDescribe().get('Opportunity').getDescribe().getRecordTypeInfosByName();
        
        //Check, if there is any record type found
        if(mapNameWithRecordType.size() > 1) {
            
            //Loop over record type
            for(Schema.RecordTypeInfo recordType : mapNameWithRecordType.values()) {
                
                //Check, if record type is available for user
                if(recordType.isAvailable() && !(recordType.isMaster())) {
                	//allRecordType.put(recordType.getRecordTypeId(), recordType.getName()); //Adding record type id in set
                    recordTypeIds.add(recordType.getRecordTypeId());
                }
            }            
        } 
        
        //Query through record types
        //sf
        query += 'IsActive FROM RecordType WHERE Id IN : recordTypeIds AND IsActive = true';
        activeRT = Database.query(query);
        
        //Check for size
        if(activeRT.size() > 0) {
            	
            //Loop over queried active record types
            for(RecordType rt : activeRT) 
                //Populate map with active record types
                activeRecordTypes.put(rt.Id, rt.Name);
        }
        
        //Check, if map has values
        if (activeRecordTypes.size() > 0) {
            
            //Flag to show record type on page
            showRecordTypeSection = true;
            
            return activeRecordTypes;
        } else
            return null; 
    }
    
    public Set<String> getOpportunityTypes() {
        Set<String> allTypes = new Set<String>();
        
        //get all picklst values of Type and hold in a set
        for (Schema.PicklistEntry p : Schema.getGlobalDescribe().get('Opportunity').getDescribe().fields.getMap().get('Type').getDescribe().getPickListValues()) {
            if(p.isActive()) 
            	allTypes.add(p.getValue());
        } 
        
        return allTypes;
    }  
    
    public List<SelectOption> getTimeofMonthSelectOptions() {
        List<SelectOption> options = new List<SelectOption>();
        options.add(new SelectOption('1', 'Last day of the month'));
        options.add(new SelectOption('2', 'Date of the month'));
        options.add(new SelectOption('3', 'Week day of certain week in the month'));
        //options.add(new SelectOption('5', 'Last business day of the month'));
        return options;
    }   
    
     public List<SelectOption> getChartPreference() {
        List<SelectOption> options = new List<SelectOption>();
        options.add(new SelectOption('1', 'Historical View'));
        options.add(new SelectOption('2', 'Today View, past Deferred as 0'));
        return options;
    } 
    
    public PageReference chartPreferenceToShow() {
        showChartPreference = false;
        if (theSetting.Chart_Pref__c == '1')
            showChartPreference = false;
        else if (theSetting.Chart_Pref__c  == '2')
            showChartPreference = true;
            
        return null;
    }
 }