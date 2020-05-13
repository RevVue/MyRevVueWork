public with sharing class RevRecScheduleSetController {
	List<RevRecView__c> scheduleList;
    private Set<String> opportunityLineItemIds ;
    
    private Opportunity theOpportunity;
    
    //Code added - 02/18/2015 - As per Advance currency management issue
    Public String oppTotalOpportunity{get;set;}
    Public String oppTotalRecognized{get;set;} 
    Public String oppTotalDeferred{get;set;}
    Public String oppTotalResidual{get;set;}  
    Public Boolean isMultiCurrencyEnabled {get;set;}
    Public Opportunity opp {get;set;}
    
    //String to hold user's currency
	String userCurrencyIsoCode = userInfo.getDefaultCurrency();
	    
    //Initilze wrapper class
    public List<revRecScheduleWrapper> revrecSchedules {get;set;}
   
    private decimal total, recognized, deferred, residual;
    
    public  RevRecScheduleSetController() {
        	
    	 //Code modified -  (10/14/2014) - Boolean variable to hold that multiCurrency enabled in org or not
    	isMultiCurrencyEnabled =  UserInfo.isMultiCurrencyOrganization();
        revrecSchedules = new List<revRecScheduleWrapper>();
    	
    	//Codde added - As per Date Instance 
    	opp = new Opportunity();
    	opp.CloseDate = Date.Today();
    	
        string opportunityId = ApexPages.currentPage().getParameters().get('opportunityId');
        
        //Code added - 02/18/2015- As per Advance currency management issue 
        String queryOpp = '';
        if(!isMultiCurrencyEnabled)
        	queryOpp += 'SELECT Id, name, StageName, CloseDate , IsWon, IsClosed, REVvue_TotalOpportunity__c, REVvue_TotalRecognized__c, REVvue_TotalResidual__c,  REVvue_TotalDeferred__c FROM Opportunity WHERE Id = :opportunityId LIMIT 1 ';
        else
        	queryOpp += 'SELECT Id, name, StageName, CloseDate , IsWon, IsClosed, CurrencyIsoCode, REVvue_TotalOpportunity__c, REVvue_TotalRecognized__c, REVvue_TotalResidual__c,  REVvue_TotalDeferred__c FROM Opportunity WHERE Id = :opportunityId LIMIT 1 ';
        	
        //Database.query
        theOpportunity = Database.query(queryOpp); 
        
        scheduleList = new List<RevRecView__c>();         
                    
        opportunityLineItemIds = new Set<String>();
        List<OpportunityLineItem> liList = 
             [SELECT Id,PricebookEntryId, Quantity, Description, UnitPrice, TotalPrice,   
                    PricebookEntry.Name,PricebookEntry.product2.id, RevRecRule__c,
                    RevRecRule__r.Name,RevRecRule__r.Recognition_Type__c ,
                    PricebookEntry.product2.RevRecRule__r.Id, 
                    PricebookEntry.product2.RevRecRule__r.name,
                    RevRecOpportunityLineItem__r.Id,
                    RevRecOpportunityLineItem__r.OpportunityLineItemId__c,
                    RevRecOpportunityLineItem__r.TotalRev__c,
                    RevRecOpportunityLineItem__r.DeferredRev__c,
                    RevRecOpportunityLineItem__r.RecognizedRev__c,
                    RevRecOpportunityLineItem__r.CalculatedAt__c,
                    RevRecOpportunityLineItem__r.ResidualAmount__c,
                    RevRecOpportunityLineItem__r.ProductName__c
                    FROM OpportunityLineItem Where OpportunityId = :opportunityId];
            total = 0;  recognized = 0; deferred = 0;  residual = 0;                        
            for(OpportunityLineItem item : liList) {
                 opportunityLineItemIds.add(item.id);
                 
                if (item.Quantity != null && item.UnitPrice != null) {
                    total += item.TotalPrice;
                }
            }
            
            //Code modified -  (1/8/2015)
            //Create dynamic query
            String query = '';
            query += 'SELECT  Date__c, OpportunityLineItemId__c, RevRecOpportunityLineItem__c, RecognizedRevTotal__c, ResidualAmountTotal__c, LineItemAmountTotal__c, DeferredRev__c, RecognizedRev__c ';
            
            //Check if multi currency enabled
            if(isMultiCurrencyEnabled)
                query += ',CurrencyIsoCode  ';
            
            query += 'from RevRecOpportunityLineItemSchedule__c where OpportunityLineItemId__c IN :opportunityLineItemIds order by Date__c LIMIT 600';
             
            //Database.query
            List<RevRecOpportunityLineItemSchedule__c> rrLIList = database.query(query);
            
            if( rrLIList.Size() > 0) {
                    
                RevRecOpportunityLineItemSchedule__c earliestSchedule = rrLIList[0];
                
                RevRecOpportunityLineItemSchedule__c lastestSchedule = rrLIList[rrLIList.Size() - 1];
                
                date firstDay = earliestSchedule.Date__c;
                date lastDay = lastestSchedule.Date__c;
                date now = date.today();
                
                List<string> lineItemList = new List<String>(opportunityLineItemIds);
                
                //step 1, put all items in datebase in a map key:  'yyyy-MM-dd' + '_' + rrLIID
                Map<string, RevRecOpportunityLineItemSchedule__c> rrLIMap = new Map<string, RevRecOpportunityLineItemSchedule__c>();
                
                for(RevRecOpportunityLineItemSchedule__c item : rrLIList) {
                    string mapKey = String.ValueOf(item.Date__c) + '_' + item.OpportunityLineItemId__c;
                    if (rrLIMap.containsKey(mapKey)) {
                        //exception, this should never happen
                        //;
                    } else {
                        rrLIMap.put(mapKey, item);
                    }
                }
                
                //step 2, poplulate a map for all the days from beginning to end
                date theDate = firstDay;
                
                Map<string, RevRecView__c> rrLIMapForEveryDay = new Map<string, RevRecView__c>();
                RevRecView__c theLastRevRecViewRecord = new RevRecView__c();
                while (theDate <= lastDay.addMonths(1)) {
                    for(string item : lineItemList) {
                        string mapKeyForTheDate = String.ValueOf(theDate) + '_' + item;
                        string mapKeyForTheDateBefore = String.ValueOf(theDate.addDays(-1)) + '_' + item;
                        if (rrLIMap.containsKey(mapKeyForTheDate)) {
                            RevRecOpportunityLineItemSchedule__c rrLISchedule = rrLIMap.get(mapKeyForTheDate);
                            RevRecView__c rrView = new RevRecView__c();
                            rrView.Date__c = theDate;
                            rrView.RecognizedRevTotal__c = rrLISchedule.RecognizedRevTotal__c;
                            rrView.RegcognizedRev__c = rrLISchedule.RecognizedRev__c;
                            rrView.ResidualAmount__c = rrLISchedule.ResidualAmountTotal__c;
                            rrView.LineItemAmount__c = rrLISchedule.LineItemAmountTotal__c;
                            rrView.DeferredRev__c = rrLISchedule.DeferredRev__c;
                            rrView.OpportunityLineItemId__c = rrLISchedule.OpportunityLineItemId__c;
                            
                            //Code modified -  (01/08/2015) - Check if multi currency enabled in org or not
                            //If true the do this 
                            if(isMultiCurrencyEnabled)
                                rrView.put('CurrencyIsoCode' , rrLISchedule.get('CurrencyIsoCode'));
        
                            rrView.RevRecOpportunityLineItem__c = rrLISchedule.RevRecOpportunityLineItem__c;
                            rrLIMapForEveryDay.put(mapKeyForTheDate, rrView);
                            theLastRevRecViewRecord = rrView;
                        } else if (rrLIMapForEveryDay.containsKey(mapKeyForTheDateBefore)) {
                            RevRecView__c lastRRView = rrLIMapForEveryDay.get(mapKeyForTheDateBefore);
                            RevRecView__c rrView = new RevRecView__c();
                            rrView.Date__c = theDate;
                            rrView.RegcognizedRev__c = 0;
                            rrView.RecognizedRevTotal__c = lastRRView.RecognizedRevTotal__c;
                            rrView.ResidualAmount__c = lastRRView.ResidualAmount__c;
                            rrView.LineItemAmount__c = lastRRView.LineItemAmount__c;
                            rrView.DeferredRev__c = lastRRView.DeferredRev__c;
                            rrView.OpportunityLineItemId__c = lastRRView.OpportunityLineItemId__c;
                            
                            //Code modified -  (01/08/2015) - Check if multi currency enabled in org or not
                            //If true the do this 
                            
                            if(isMultiCurrencyEnabled)
                                rrView.put('CurrencyIsoCode' , lastRRView.get('CurrencyIsoCode'));
        
                            rrView.RevRecOpportunityLineItem__c = lastRRView.RevRecOpportunityLineItem__c;
                            rrLIMapForEveryDay.put(mapKeyForTheDate, rrView);
                            theLastRevRecViewRecord = rrView;
                        }
                    }
                    theDate = theDate.addDays(1);
                }
                
                //step 3, output todays sum up data
                for(string item : lineItemList) {
                    string mapKeyForToday = String.ValueOf(now) + '_' + item;
                     
                    if (rrLIMapForEveryDay.containsKey(mapKeyForToday)) {
                        RevRecView__c rrViewItem = rrLIMapForEveryDay.get(mapKeyForToday);
                        recognized += rrViewItem.RecognizedRevTotal__c;
                        residual += rrViewItem.ResidualAmount__c;                       
                        deferred += rrViewItem.DeferredRev__c;  
                    } else if (now >= lastDay) {
                        recognized += theLastRevRecViewRecord.RecognizedRevTotal__c;
                        residual += theLastRevRecViewRecord.ResidualAmount__c;                      
                        deferred += theLastRevRecViewRecord.DeferredRev__c; 
                    }                       
                }
                
                System.debug('@@@@@@@@@@@@@@@@2' + total);                
                System.debug('@@@@@@@@@@@@@@@@2' + deferred);
                System.debug('@@@@@@@@@@@@@@@@2' + recognized);  
                System.debug('@@@@@@@@@@@@@@@@2' + residual);
                    
                theOpportunity.REVvue_TotalOpportunity__c = total; 
                theOpportunity.REVvue_TotalRecognized__c = recognized;
                theOpportunity.REVvue_TotalResidual__c = residual;                
                theOpportunity.REVvue_TotalDeferred__c = deferred;
                
                //Code added - 02/18/22015 -  As per Advance currency management issue 
                //Calling utility method to get the Amount formatted
                //Checking if multi currency enabled org
                if(isMultiCurrencyEnabled) {
                	
                	System.debug('Utility Call...@@@');
                	
                	//Inlilize class
    		    	Utility utl = new Utility(theOpportunity);
			        
			        //Checking for null
			        if(theOpportunity.REVvue_TotalOpportunity__c != null)
			        	oppTotalOpportunity = utl.calculateAmountInCurrency(String.valueOf(theOpportunity.get('CurrencyIsoCode')), theOpportunity.REVvue_TotalOpportunity__c);
			        else
			        	oppTotalOpportunity = theOpportunity.get('CurrencyIsoCode') + ' 0.00' + '<br/>' + '( ' + userCurrencyIsoCode + ' 0.00 )';
			        	
			        //Checking for null
			        if(theOpportunity.REVvue_TotalRecognized__c != null)
			        	oppTotalRecognized = utl.calculateAmountInCurrency(String.valueOf(theOpportunity.get('CurrencyIsoCode')), theOpportunity.REVvue_TotalRecognized__c);
			        else
			        	oppTotalRecognized = theOpportunity.get('CurrencyIsoCode') + ' 0.00' + '<br/>' + '( ' + userCurrencyIsoCode + ' 0.00 )';
			        
			        //Checking for null
			        if(theOpportunity.REVvue_TotalDeferred__c != null)
			        	oppTotalDeferred = utl.calculateAmountInCurrency(String.valueOf(theOpportunity.get('CurrencyIsoCode')), theOpportunity.REVvue_TotalDeferred__c);
			        else
			       		oppTotalDeferred = theOpportunity.get('CurrencyIsoCode') + ' 0.00' + '<br/>' + '( ' + userCurrencyIsoCode + ' 0.00 )';
			        
			        //Checking for null	
			        if(theOpportunity.REVvue_TotalResidual__c != null)
			        	oppTotalResidual = utl.calculateAmountInCurrency(String.valueOf(theOpportunity.get('CurrencyIsoCode')), theOpportunity.REVvue_TotalResidual__c);
                	else
                		oppTotalResidual = theOpportunity.get('CurrencyIsoCode') + ' 0.00' + '<br/>' + '( ' + userCurrencyIsoCode + ' 0.00 )';
                    		
                }
                    
                //step 4, based company settings, sample one record for each month, and put in the database
                RevRecAppSetting__c theSetting;
                List<RevRecAppSetting__c> theSettingList = [select Id, Name, Opportunity_Stage__c, Opportunity_Type__c,  Selected_Start_Date_Types__c, Selected_End_Date_Types__c, Time_of_Month_Selection_Types__c, Time_of_Month_Selection_Types_tr__c,  Certain_date_of_month__c, Certain_date_of_month_tr__c, Certain_weekday__c, Certain_weekday_tr__c,Certain_weekday_day__c, Certain_weekday_day_tr__c, Certain_days_before_last_weekday__c, Certain_days_before_last_weekday_tr__c, Certain_days_before_last_weekday_day__c, Certain_days_before_last_weekday_day_tr__c, DiagnosticsEnabled__c FROM  RevRecAppSetting__c  WHERE Name='AppSetting' LIMIT 1 ];
                if (theSettingList.Size() == 0 ) {
                    theSetting = new RevRecAppSetting__c(Name='AppSetting', 
                                                        Time_of_Month_Selection_Types__c = '1' ,
                                                        Time_of_Month_Selection_Types_tr__c = '1'   
                                                        );
                    //insert theSetting;
                } else {
                    theSetting = theSettingList[0];
                }     
                theDate = firstDay;
                while (theDate <= lastDay.addMonths(1)) {
                    Date transactionDate = theDate;
                    if ( theSetting.Time_of_Month_Selection_Types__c == '1') {//    the day is last day of month
                        transactionDate = theDate.toStartOfMonth().addMonths(1).addDays(-1);
                    } else if (theSetting.Time_of_Month_Selection_Types__c == '2') {       // Date of the month
                        integer transactionDay = Integer.valueOf(theSetting.Certain_date_of_month__c);
                        transactionDate = date.newinstance(theDate.year(), theDate.Month(),transactionDay); 
                    } else if (theSetting.Time_of_Month_Selection_Types__c == '3') {       //certain weekday of certain week
                        transactionDate = RevRecHelper.GetDateByCertainWeekCertainDayOfWeek(theDate, theSetting.Certain_weekday_tr__c, theSetting.Certain_weekday_day_tr__c);
                    }
                        
                    for(string item : lineItemList) {
                        string mapKeyForTheDate = String.ValueOf(transactionDate) + '_' + item;
                        if (rrLIMapForEveryDay.containsKey(mapKeyForTheDate)) {
                            RevRecView__c rrView = rrLIMapForEveryDay.get(mapKeyForTheDate); 
                            scheduleList.add(rrView);
                        }
                    }
                    theDate = theDate.addMonths(1);
                }
            }
           getSchedules();
        }
        public PageReference UpdateRRView(){
            List<RevRecView__c> garbage = [select id, name from RevRecView__c where OpportunityLineItemId__c in :opportunityLineItemIds];
            delete(garbage);
            insert(scheduleList);
            return null;
        }
        
        public List<RevRecScheduleTemp__c> getSchedules() {

                List<RevRecScheduleTemp__c> schedules = new List<RevRecScheduleTemp__c>();
                Map <string, RevRecScheduleTemp__c> scheduleMap = new Map <string, RevRecScheduleTemp__c>();
                List<RevRecView__c> allRecords = scheduleList;
                integer recordsSize = allRecords.size();
                if (recordsSize == 0) return schedules;
                
                Date minDate = allRecords[0].Date__c;  
                Date maxDate = allRecords[recordsSize-1].Date__c;

                for(Integer i = 0; i < recordsSize; i++) {
                    RevRecView__c ar = allRecords[i];
                    RevRecScheduleTemp__c item = new RevRecScheduleTemp__c();
                    item.DeferredRev__c = ar.DeferredRev__c;
                    item.RecognizedRev__c = ar.RegcognizedRev__c;
                    item.RecognizedRevTotal__c = ar.RecognizedRevTotal__c;
                    item.ResidualAmountTotal__c = ar.ResidualAmount__c;
                    item.LineItemsTotal__c = ar.LineItemAmount__c;
                    
                    //Code modified -  (01/08/2015) - Check if multi currency enabled in org or not
                    //If true the do this 
                    if(isMultiCurrencyEnabled)
                        item.put('CurrencyIsoCode' , ar.get('CurrencyIsoCode'));
                    
                    item.Year__c = '' + (ar.Date__c).year();
                    item.Month__c = '' + (ar.Date__c).month();
                      
                    item.MonthAndYear__c = item.Year__c + '/' + item.Month__c;
                    if (scheduleMap.containsKey(item.MonthAndYear__c)) {
                            RevRecScheduleTemp__c existingItem = scheduleMap.get(item.MonthAndYear__c);
                            item.DeferredRev__c = item.DeferredRev__c + existingItem.DeferredRev__c;
                            
                            //Code modified -  (01/08/2015) - Check if multi currency enabled in org or not
                            //If true the do this 
                            if(isMultiCurrencyEnabled)
                                item.put('CurrencyIsoCode' , ar.get('CurrencyIsoCode'));
                            
                            item.RecognizedRev__c = item.RecognizedRev__c + existingItem.RecognizedRev__c;
                            item.RecognizedRevTotal__c = item.RecognizedRevTotal__c + existingItem.RecognizedRevTotal__c;
                            item.ResidualAmountTotal__c = item.ResidualAmountTotal__c + existingItem.ResidualAmountTotal__c;
                            item.LineItemsTotal__c = item.LineItemsTotal__c + existingItem.LineItemsTotal__c;
                            scheduleMap.put(item.MonthAndYear__c, item);
                    } else {
                            scheduleMap.put(item.MonthAndYear__c, item);
                    }
                }
                
                Integer squenceNum = 0;
                while (minDate <= maxDate.addMonths(1)) {
                        string keystr = minDate.year() + '/' + minDate.month();
                        RevRecScheduleTemp__c item = null;
                        if (scheduleMap.containsKey(keystr)) {
                            item = scheduleMap.get(keystr);
                            if (squenceNum == 0) {
                                item.RecognizedRev__c = item.RecognizedRevTotal__c;
                            } 
                            else
                            {
                                item.RecognizedRev__c = item.RecognizedRevTotal__c - schedules[squenceNum -1].RecognizedRevTotal__c;
                            }
                            squenceNum++;
                            item.Sequence__c = squenceNum;                        
                            schedules.add(item);
                        }
                        minDate = minDate.addMonths(1);
                }
                
                //Checking for multi currency enabled
                if(isMultiCurrencyEnabled) {
                	
                	System.debug('Utility Call...@@@');
                	//Inlilize class
        		    Utility utl = new Utility(theOpportunity);
				        
                	//Variables
                	Decimal seq = 0;
                	String schDef;
                	String schRevRec;
                	String schRevRecTotal;
                	String schYear;
                	String schMonth;
                	
                	//checking for list size
                	if(schedules.size() > 0) {
	                	
	                	//Loop throgh Schedules
	                	for(RevRecScheduleTemp__c sch : schedules) {
	                		
	                		//Checking for null
	                		if(sch.Sequence__c != null)
	                			seq = sch.Sequence__c;
	                		
	                		//Checking for null
	                		if(sch.DeferredRev__c != null)
	                			schDef = utl.calculateAmountInCurrency(String.valueOf(theOpportunity.get('CurrencyIsoCode')), sch.DeferredRev__c);
	                		else
	                			schDef = theOpportunity.get('CurrencyIsoCode') + ' 0.00' + '<br/>' + '( ' + userCurrencyIsoCode + ' 0.00 )';
	                		
	                		//Checking for null
	                		if(sch.RecognizedRev__c != null)
	                			schRevRec = utl.calculateAmountInCurrency(String.valueOf(theOpportunity.get('CurrencyIsoCode')), sch.RecognizedRev__c);
	                		else
	                			schRevRec = theOpportunity.get('CurrencyIsoCode') + ' 0.00' + '<br/>' + '( ' + userCurrencyIsoCode + ' 0.00 )';
	                		
	                		
	                		//Checking for null
	                		if(sch.RecognizedRevTotal__c != null)
	                			schRevRecTotal = utl.calculateAmountInCurrency(String.valueOf(theOpportunity.get('CurrencyIsoCode')), sch.RecognizedRevTotal__c);
	                		else
	                			schRevRecTotal = theOpportunity.get('CurrencyIsoCode') + ' 0.00' + '<br/>' + '( ' + userCurrencyIsoCode + ' 0.00 )';
	                		
	                		//Checking for year                  
	                		if(sch.Year__c != null)
	                			schYear = sch.Year__c; 
	                		
	                		//Checking for null
	                		if(sch.Month__c != null)
	                			schMonth = sch.Month__c;
	                		                      
	                	  revrecSchedules.add(new revRecScheduleWrapper(seq,schDef,schRevRec,schRevRecTotal,schYear,schMonth));
	                	}
                	}
                }
                return schedules;
        }
    public Opportunity getOpportunity() { return theOpportunity; }
    
    public PageReference cancel() { return new PageReference('/' + theOpportunity.id) ;  }      
        
    public PageReference ExportToExcel() { 
        PageReference pr = Page.RevRecOpportunitySchedulesOutputAsExcel;
        pr.getParameters().put('opportunityId',theOpportunity.id);
        return pr ;  
    } 
     
	//Code added - 02/20/2015 - wrapper class to hold schedule prroperties
    public class revRecScheduleWrapper {
    	
    	//Properties
    	public Decimal sequence {get;set;}
    	public string scheduleDeferred {get;set;}
    	public string scheduleRecRev {get;set;}
    	public string scheduleRecRevTotal {get;set;}
    	public String schYear{get;set;}
    	public string month {get;set;}
    	
    	//Constructer
    	public revRecScheduleWrapper(Decimal sequence, string scheduleDeferred, string scheduleRecRev, string scheduleRecRevTotal , string schYear, String month) {
    		
    		this.sequence = sequence;
    		this.scheduleDeferred = scheduleDeferred;
    		this.scheduleRecRev = scheduleRecRev;
    		this.scheduleRecRevTotal = scheduleRecRevTotal;
    		this.schYear = schYear;
    		this.month = month;     
    	} 
    }       
}