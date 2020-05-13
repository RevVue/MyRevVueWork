/**
 *  Description     :   Class to calculate schedules on opportunity level.
 *
 *  Created By      :   Bill Feeheley
 *
 *  Created Date    :   29/07/2016
 *
 *  Version         :   V_1.0
 *
 *  Revision Log    :   V_1.0 - Created
 **/
public with sharing class RevRecScheduleSetControllerCopy { 
    
    //Properties
    public Opportunity opp {get;set;}
    public Boolean isMultiCurrencyEnabled {get;set;}
    public List<RevRecOpportunityLineItemSchedule__c> rrOLISchedules{get;set;}
    public String oppTotalOpportunity{get;set;}
    public String oppTotalRecognized{get;set;} 
    public String oppTotalDeferred{get;set;}
    public String oppTotalResidual{get;set;}
    public String currencyFormate {get;set;}
    
    //Code is added on 11/16/2017 for weighted calculation
    public String oppTotalOpportunityWei{get;set;}
    public String oppTotalRecognizedWei{get;set;} 
    public String oppTotalDeferredWei{get;set;}
    public String oppTotalResidualWei{get;set;} 
    
    private String opportunityId;
    private transient Opportunity theOpportunity;
    private transient Set<Id> scheduleIds = new Set<Id>();
    private transient Set<Id> opportunityLineItemIds;
    private transient Double total, recognized, deferred, residual;
    
    //Initilze wrapper class
    public List<revRecScheduleWrapper> revrecSchedules {get;set;}
    
    //String to hold user's currency
    transient String userCurrencyIsoCode = userInfo.getDefaultCurrency();
    
    //List to hold schedule if milticurrency is not enable
    public List<RevRecOpportunityLineItemSchedule__c> rrOpportunityLineItemSchedules {get;set;}
	transient RevRecAppSetting__c theSetting;
	public Boolean setPastSchDeferredWith0 {get;set;}
    
    //Added on 06/27/2018 - Enhancement to show charts on the page for revenues
    //List to hold chart data
    public List<BarChartDataWrapper> barChartData {get; set;}
    transient List<RevRecOpportunityLineItemSchedule__c> schedules = new List<RevRecOpportunityLineItemSchedule__c>();
    
    //Boolean variables to show visibility of charts
    public Boolean isShowRevenueWeiChart {get; set;}
	public Boolean isShowForecastedChart {get; set;}
	public Boolean isShowPastLegends {get;set;}
	public Boolean isShowFutureLegends {get; set;}
	
	//Code added - 13 July, 2018- Cumulative Recognized Revenue added on page
	public List<RevRecLineItemScheduleWrapper> scheduleWrapper {get; set;}
	
    //Constructor
    public  RevRecScheduleSetControllerCopy() {
        
        //Fetching user currency
        isMultiCurrencyEnabled = UserInfo.isMultiCurrencyOrganization();
        currencyFormate = userInfo.getDefaultCurrency();
        revrecSchedules = new List<revRecScheduleWrapper>();
        
        //Codde added - As per Date Instance 
    	opp = new Opportunity();
    	opp.CloseDate = Date.Today();
        setPastSchDeferredWith0 = false;
        
        //Added on 06/27/2018 - Enhancement for chart 
        barChartData = new List<BarChartDataWrapper>();
        isShowRevenueWeiChart = false;
		isShowForecastedChart = false;
        isShowPastLegends = false;
        isShowFutureLegends = false;
        scheduleWrapper = new List<RevRecLineItemScheduleWrapper>();
        
        opportunityId = ApexPages.currentPage().getParameters().get('opportunityId');
        
        //Variable to hold query for opportunity
        transient String queryOpp = '';
        
        List<RevRecAppSetting__c> theSettingList = [Select Chart_Pref__c FROM  RevRecAppSetting__c  WHERE Name='AppSetting' LIMIT 1 ];
              
        if (theSettingList.Size() > 0 ) {
            theSetting = theSettingList[0];
            if(theSetting.Chart_Pref__c == '1')
            	setPastSchDeferredWith0 = false;
            else if(theSetting.Chart_Pref__c == '2')
                setPastSchDeferredWith0 = true;
        } 
        
        //Check if, multicurrency is enable
        if(!isMultiCurrencyEnabled)
            queryOpp += 'SELECT Id, name, StageName, Amount, CloseDate , IsWon, IsClosed, REVvue_TotalOpportunity__c, REVvue_TotalRecognized__c, REVvue_TotalResidual__c,  REVvue_TotalDeferred__c, REVvue_Total_Opp_wei__c, REVvue_TotalDeferredwei__c, REVvue_TotalRecognizedwei__c	, REVvue_TotalResidualwei__c, Probability FROM Opportunity WHERE Id = :opportunityId LIMIT 1 ';
        else
            queryOpp += 'SELECT Id, name, StageName, Amount, CloseDate , IsWon, IsClosed, CurrencyIsoCode, REVvue_TotalOpportunity__c, REVvue_TotalRecognized__c, REVvue_TotalResidual__c,  REVvue_TotalDeferred__c, REVvue_Total_Opp_wei__c, REVvue_TotalDeferredwei__c, REVvue_TotalRecognizedwei__c, REVvue_TotalResidualwei__c, Probability FROM Opportunity WHERE Id = :opportunityId LIMIT 1';
        
        //Database.query for opportunity
        theOpportunity = Database.query(queryOpp); 
        
        //Set flag for Revenue Weighted chart 
        if(theOpportunity.Probability < 100)
        	isShowRevenueWeiChart = true;
        	
        //Fetching all line items
        transient List<OpportunityLineItem> olis = [SELECT Id, Quantity, UnitPrice, TotalPrice FROM OpportunityLineItem 
                                                    Where OpportunityId = :opportunityId];
        
        //Initiliazation
        opportunityLineItemIds = new Set<Id>();
        total = 0.0;
        
        //Loop over oli to get oli id's and total amount
        for(OpportunityLineItem item : olis) {
            
            //Adding oli id's in set
            opportunityLineItemIds.add(item.id);
            
            //Check if, quantity and unit price is not null
            if (item.Quantity != null && item.UnitPrice != null)
                total += item.TotalPrice;
        }
        
        //Variable to hold query for schedules
        transient String query = '';
        
        //Create dynamic query
        query += 'SELECT  Date__c, OpportunityLineItemId__c, RevRecOpportunityLineItem__c, RecognizedRevTotal__c, ResidualAmountTotal__c, LineItemAmountTotal__c, DeferredRev__c, RecognizedRev__c, RecMonth__c, RecYear__c, Sequence__c, RecRevWei__c, DefReWei__c, ForecastedRev__c, ForeRevWei__c ';
        
        //Check if multi currency enabled
        if(isMultiCurrencyEnabled)
            query += ',CurrencyIsoCode  ';
        
        query += 'from RevRecOpportunityLineItemSchedule__c where External_OpportunityLineItemId__c IN :opportunityLineItemIds order by Date__c';
        
        //Database.query for schedules
        List<RevRecOpportunityLineItemSchedule__c> rrOLISs = database.query(query);
        
        //Initiliazation
        rrOLISchedules = new List<RevRecOpportunityLineItemSchedule__c>(); 
        recognized = 0.0; 
        deferred = 0.0;  
        residual = 0.0;
        
        //Inlilize class
        Utility utl = new Utility(theOpportunity);

        //Map to hold schedules with month and year as key value to rollup schedules
        Map<String, RevRecOpportunityLineItemSchedule__c> mapStringWithRROLISchedule = new Map<String, RevRecOpportunityLineItemSchedule__c>();
        rrOpportunityLineItemSchedules = new List<RevRecOpportunityLineItemSchedule__c>();
        
        //Check if, schedules found
        if(rrOLISs.size() > 0) {
            
            //Loop over schedules
            for(RevRecOpportunityLineItemSchedule__c item : rrOLISs) {
                //Check for null values
                if(item.ForecastedRev__c == null)
                	item.ForecastedRev__c = 0.00;
                	
            	if(item.ForeRevWei__c == null)
            		item.ForeRevWei__c = 0.00;
                
                //Creating unique key vallue for map
                String mapKey =  String.valueOf(item.Date__c.month()) + '-' + String.valueOf(item.Date__c.year());
                
                //Check to get OLI level Residual amount
                if(!scheduleIds.contains(item.RevRecOpportunityLineItem__c)) {
                        
                    residual += item.ResidualAmountTotal__c;
                    scheduleIds.add(item.RevRecOpportunityLineItem__c);
                }
                
                //Check if, map contains key then roll up existing with new one
                if(mapStringWithRROLISchedule.containsKey(mapKey)) {
                    
                    //Schedule to hold existing record
                    RevRecOpportunityLineItemSchedule__c existingRROLISchedule = mapStringWithRROLISchedule.get(MapKey);
                    
                    //Adding new instance value
                    existingRROLISchedule.RecognizedRev__c += item.RecognizedRev__c;
                    existingRROLISchedule.DeferredRev__c += item.DeferredRev__c;
                    existingRROLISchedule.RecognizedRevTotal__c += item.RecognizedRevTotal__c;
                    existingRROLISchedule.ResidualAmountTotal__c += item.ResidualAmountTotal__c;
                    //Code is added on 11/16/2017 for weighted calculation
                    existingRROLISchedule.RecRevWei__c += item.RecRevWei__c;
                    existingRROLISchedule.DefReWei__c += item.DefReWei__c;
                    existingRROLISchedule.ForecastedRev__c += item.ForecastedRev__c;
                    existingRROLISchedule.ForeRevWei__c += item.ForeRevWei__c;
                } else 
                    mapStringWithRROLISchedule.put(mapKey, item);
            }
            
            //Check if, map is not null
            if(mapStringWithRROLISchedule.size() > 0) {
                
                //Variables
                String schDef;
                String schRevRec;
                String schDefWei;
                String schRevRecWei;
                String schRevRecTotal;
                String schYear;
                String schMonth;
                Date schDate;
                Integer sequence = 0;
                Double tempDiferredRev = total;
                Decimal totalSchRecRev = 0.00;
                Decimal totalSchRecRevWei = 0.00;
                Decimal totalSchForecastRev = 0.00;
                Decimal totalSchForecastRevWei = 0.00;
                String schForeWei;
                
                //Loop over roll up schdules
                for(RevRecOpportunityLineItemSchedule__c item : mapStringWithRROLISchedule.values()) {
                    
                    //Calculation differred amount for each roll up schedule
                    tempDiferredRev = tempDiferredRev - item.RecognizedRev__c;
                    
                    //Assigning differreed amount
                    item.DeferredRev__c = tempDiferredRev;
                    
                    //Calculating total amount for opportunity
                    //Assigning current diferred amount
                    if(item.Date__c <= Date.today())
                        deferred = tempDiferredRev; 
                    recognized += item.RecognizedRev__c;
                    
                    //Assign schedule date
                    schDate = item.Date__c;
                    
                    if(item.RecognizedRev__c != null)
	                    totalSchRecRev += item.RecognizedRev__c; 
                    if(item.RecRevWei__c != null)
                        totalSchRecRevWei += item.RecRevWei__c;
                    if(item.ForecastedRev__c != null)
                        totalSchForecastRev += item.ForecastedRev__c;
                    //Check for null values
                    if(item.ForeRevWei__c != null)
            			totalSchForecastRevWei += item.ForeRevWei__c;
                    
                    if(isMultiCurrencyEnabled) {
                        
                        //Checking for null
                        if(item.DeferredRev__c != null)
                            schDef = utl.calculateAmountInCurrency(String.valueOf(theOpportunity.get('CurrencyIsoCode')), item.DeferredRev__c);
                        else
                            schDef = theOpportunity.get('CurrencyIsoCode') + ' 0.00' + '<br/>' + '( ' + userCurrencyIsoCode + ' 0.00 )';
                        
                        //Checking for null
                        if(item.RecognizedRev__c != null)
                            schRevRec = utl.calculateAmountInCurrency(String.valueOf(theOpportunity.get('CurrencyIsoCode')), item.RecognizedRev__c);
                        else
                            schRevRec = theOpportunity.get('CurrencyIsoCode') + ' 0.00' + '<br/>' + '( ' + userCurrencyIsoCode + ' 0.00 )';
                        
                        //Checking for null
                        if(item.DefReWei__c != null)
                            schDefWei = utl.calculateAmountInCurrency(String.valueOf(theOpportunity.get('CurrencyIsoCode')), (item.DeferredRev__c*theOpportunity.Probability)/100);
                        else
                            schDefWei = theOpportunity.get('CurrencyIsoCode') + ' 0.00' + '<br/>' + '( ' + userCurrencyIsoCode + ' 0.00 )';
                        
                        //Checking for null
                        if(item.RecRevWei__c != null)
                            schRevRecWei = utl.calculateAmountInCurrency(String.valueOf(theOpportunity.get('CurrencyIsoCode')), item.RecRevWei__c);
                        else
                            schRevRecWei = theOpportunity.get('CurrencyIsoCode') + ' 0.00' + '<br/>' + '( ' + userCurrencyIsoCode + ' 0.00 )';
                        
                        //Checking for null
                        if(item.ForeRevWei__c != null)
                            schForeWei = utl.calculateAmountInCurrency(String.valueOf(theOpportunity.get('CurrencyIsoCode')), item.ForeRevWei__c);
                        else
                            schForeWei = theOpportunity.get('CurrencyIsoCode') + ' 0.00' + '<br/>' + '( ' + userCurrencyIsoCode + ' 0.00 )';
                            
                        //Checking for null
                        if(item.RecognizedRevTotal__c != null)
                            schRevRecTotal = utl.calculateAmountInCurrency(String.valueOf(theOpportunity.get('CurrencyIsoCode')), item.RecognizedRevTotal__c);
                        else
                            schRevRecTotal = theOpportunity.get('CurrencyIsoCode') + ' 0.00' + '<br/>' + '( ' + userCurrencyIsoCode + ' 0.00 )';
                        
                        //Checking for year                  
                        if(item.RecYear__c != null)
                            schYear = String.valueOf(item.RecYear__c); 
                        
                        //Checking for null
                        if(item.RecMonth__c != null)
                            schMonth = String.valueOf(item.RecMonth__c);
                        
                        //Sequence to serilaize recoreds
                        sequence++;
                        
                        //Wrapper class call
                        revrecSchedules.add(new revRecScheduleWrapper(sequence, schDef,schRevRec, schDefWei,schRevRecWei, schRevRecTotal,schYear,schMonth,schDate,totalSchRecRev.setScale(2),totalSchRecRevWei.setScale(2),totalSchForecastRev.setScale(2),schForeWei));
                    }
                    
                  	else 
                        rrOpportunityLineItemSchedules.add(item); //Adding schedules if multi currency is not enabled
                  	
                  	//Add values to the list to hold chart data
                  	barChartData.add(new BarChartDataWrapper(null, null, null, item.RecognizedRev__c, Math.abs(item.DeferredRev__c), item.RecRevWei__c, 
                                                             Math.abs((item.DeferredRev__c*theOpportunity.Probability)/100), Date.valueOf(schDate).format(), 
                                                             item.ForecastedRev__c, 0, item.ForeRevWei__c, schDate, totalSchRecRev, totalSchRecRevWei, totalSchForecastRev, totalSchForecastRev));
                }
                
                //Check for size
                if(rrOpportunityLineItemSchedules.size() > 0) {
                	totalSchRecRev = 0.00;
                    totalSchRecRevWei = 0.00;
                    totalSchForecastRev = 0.00;
                    totalSchForecastRevWei = 0.00;
                	//Loop over rrOpportunityLineItemSchedules
	                for(RevRecOpportunityLineItemSchedule__c sch : rrOpportunityLineItemSchedules) {
	                	totalSchRecRev += sch.RecognizedRev__c; 
                        totalSchRecRevWei += sch.RecRevWei__c;
                        totalSchForecastRev += sch.ForecastedRev__c;
                        //Check for null values
                        if(sch.ForeRevWei__c != null)
                            totalSchForecastRevWei += sch.ForeRevWei__c;
                        
	                	scheduleWrapper.add(new RevRecLineItemScheduleWrapper(sch, totalSchRecRev, totalSchRecRevWei, totalSchForecastRev));
	                }
                }
                //Check for size
                if(barChartData.size() > 0) {
                	
                	//Loop over bar chart data
					for(BarChartDataWrapper bar : barChartData) {
						
						//Set visibility for forecasted Revenue chart
		    			if(bar.Forecasted > 0) {
		    				isShowForecastedChart = true;
		        			break;
		    			}
					}
					for(BarChartDataWrapper bar : barChartData) {
						
				       	if(bar.schDate < Date.today()) 
				       		isShowPastLegends = true;
			       		else
			       			isShowFutureLegends = true;
		       			if(isShowPastLegends == true && isShowFutureLegends == true)
		       				break;
					}
		    	}
            }
        }
       
        //Assgining total values on opportunity
        theOpportunity.REVvue_TotalOpportunity__c = total; 
        theOpportunity.REVvue_TotalResidual__c = residual;
        theOpportunity.REVvue_Total_Opp_wei__c = (total * theOpportunity.Probability) / 100; 
        theOpportunity.REVvue_TotalResidualwei__c = (residual * theOpportunity.Probability) / 100;  
        
        if(deferred == 0) {            
	        theOpportunity.REVvue_TotalDeferred__c = total;
	        theOpportunity.REVvue_TotalRecognized__c = deferred;
        } else {
        	theOpportunity.REVvue_TotalDeferred__c = deferred;
	        theOpportunity.REVvue_TotalRecognized__c = Math.abs(total- deferred);
        }
        
        theOpportunity.REVvue_TotalDeferredwei__c = (theOpportunity.REVvue_TotalDeferred__c * theOpportunity.Probability)/100;
        theOpportunity.REVvue_TotalRecognizedwei__c	 = (theOpportunity.REVvue_TotalRecognized__c * theOpportunity.Probability)/100;
        
        //Checking if multi currency enabled org
        if(isMultiCurrencyEnabled) {
            
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
            
            //Code is added on  11/16/2017 weighted calculation  
            //Checking for null
            if(theOpportunity.REVvue_Total_Opp_wei__c	 != null)
                oppTotalOpportunityWei = utl.calculateAmountInCurrency(String.valueOf(theOpportunity.get('CurrencyIsoCode')), theOpportunity.REVvue_Total_Opp_wei__c	);
            else
                oppTotalOpportunityWei = theOpportunity.get('CurrencyIsoCode') + ' 0.00' + '<br/>' + '( ' + userCurrencyIsoCode + ' 0.00 )';
            
            //Checking for null
            if(theOpportunity.REVvue_TotalRecognizedwei__c != null)
                oppTotalRecognizedWei = utl.calculateAmountInCurrency(String.valueOf(theOpportunity.get('CurrencyIsoCode')), theOpportunity.REVvue_TotalRecognizedwei__c);
            else
                oppTotalRecognizedWei = theOpportunity.get('CurrencyIsoCode') + ' 0.00' + '<br/>' + '( ' + userCurrencyIsoCode + ' 0.00 )';
            
            //Checking for null
            if(theOpportunity.REVvue_TotalDeferredwei__c != null)
                oppTotalDeferredWei = utl.calculateAmountInCurrency(String.valueOf(theOpportunity.get('CurrencyIsoCode')), theOpportunity.REVvue_TotalDeferredwei__c);
            else
                oppTotalDeferredWei = theOpportunity.get('CurrencyIsoCode') + ' 0.00' + '<br/>' + '( ' + userCurrencyIsoCode + ' 0.00 )';
            
            //Checking for null 
            if(theOpportunity.REVvue_TotalResidualwei__c != null)
                oppTotalResidualWei = utl.calculateAmountInCurrency(String.valueOf(theOpportunity.get('CurrencyIsoCode')), theOpportunity.REVvue_TotalResidualwei__c);
            else
                oppTotalResidualWei = theOpportunity.get('CurrencyIsoCode') + ' 0.00' + '<br/>' + '( ' + userCurrencyIsoCode + ' 0.00 )';
      }
    }
    
    /**
     *  @Description    :   This method is used to get the opportunity
     *
     *  @args           :   void
     *
     *  @return Type    :   opportunity
     **/
    public Opportunity getOpportunity() { return theOpportunity; }
    
    /**
     *  @Description    :   This method is used to back on opportunity
     *
     *  @args           :   void
     *
     *  @return Type    :   PageReference
     **/
    public PageReference cancel() { return new PageReference('/' + opportunityId) ;  }      
    
    /**
     *  @Description    :   This method is used to export the schedules in excel file.
     *
     *  @args           :   void
     *
     *  @return Type    :   PageReference
     **/
    public PageReference ExportToExcel() { 
        
        PageReference pr = Page.RevRecOpptySchedulesOutputAsExcelCopy;
        pr.getParameters().put('opportunityId',opportunityId);
        return pr ;  
    } 
    
    /**
     *  Description     :   revRecScheduleWrapper class to hold shedules and show them on page.
     **/
    public class revRecScheduleWrapper {
        
        //Properties
        public Integer sequence {get;set;}
        public string scheduleDeferred {get;set;}
        public string scheduleRecRev {get;set;}
        public string scheduleDeferredWei {get;set;}
        public string scheduleRecRevWei {get;set;}
        public string scheduleRecRevTotal {get;set;}
        public String schYear{get;set;}
        public string month {get;set;}
        public Date scheduleDate {get; set;}
        public Decimal scheduleRecRevCumulative {get; set;}
        public Decimal schRecRevWeiCumulative {get; set;}
        public Decimal schForecastedRevCumulative {get; set;}
        public String schForecastedRevWei {get; set;}
        
        //Constructor
        public revRecScheduleWrapper(Integer sequence, String scheduleDeferred, String scheduleRecRev, String scheduleDeferredWei, 
                                     String scheduleRecRevWei, String scheduleRecRevTotal , String schYear, String month, Date scheduleDate, 
                                     Decimal scheduleRecRevCumulative, Decimal schRecRevWeiCumulative, Decimal schForecastedRevCumulative, 
                                     String schForecastedRevWei) {
            
            //Assigning in wrapper valiable
            this.sequence = sequence;
            this.scheduleDeferred = scheduleDeferred;
            this.scheduleRecRev = scheduleRecRev;
            this.scheduleDeferredWei = scheduleDeferredWei;
            this.scheduleRecRevWei = scheduleRecRevWei;
            this.scheduleRecRevTotal = scheduleRecRevTotal;
            this.schYear = schYear;
            this.month = month;
            this.scheduleDate = scheduleDate;
            this.scheduleRecRevCumulative = scheduleRecRevCumulative;
			this.schRecRevWeiCumulative = schRecRevWeiCumulative;
			this.schForecastedRevCumulative = schForecastedRevCumulative;
            this.schForecastedRevWei = schForecastedRevWei;
        } 
    } 
    
	/**
     *  @Description    :   This method is used to set colors in the wrapper list that hold chart data.
     *
     *  @args           :   void
     *
     *  @return Type    :   String
     **/
     public string getColors(){
     	
     	//Variable declaration
        string colorCodes = '';
        
        //Check for size
        if(barChartData.size() > 0) {
        	
        	//Loop over wrapper list and set colors to it
        	for(BarChartDataWrapper recData : barChartData)
	            colorCodes += recData.colorCode + ',' + recData.colorCodeZero + ',' + recData.colorCodeWei + ',';
        }
        return colorCodes;
     }  
     
    /**
     *  Description     :   BarChartDataWrapper class to hold chart data for schedules.
     **/
    public class BarChartDataWrapper{
    	
    	//Declarations
    	public String colorCode {get; set;}
    	public String colorCodeZero {get; set;}
    	public String colorCodeWei {get; set;}
        public Decimal Recognized {set;get;}
        public Decimal Deferred {set;get;}
        public Decimal RecognizedWeighted {set;get;}
        public Decimal DeferredWeighted {set;get;}
        public String transDate {set;get;}
        public Decimal Forecasted {set;get;}
        public Decimal totalForecastedZero {set;get;}
        public Decimal ForecastedWeighted {set;get;}
        public Date schDate {get; set;}
        public Decimal RecognizedCumulative {get; set;}
        public Decimal RecognizedWeightedCumulative {get; set;}
        public Decimal ForecastedCumulative {get; set;}
        public Decimal ForecastedWeiCummulative {get; set;}
        
        //Constructor
        public BarChartDataWrapper(String colorCode, String colorCodeZero, String colorCodeWei, Decimal Recognized, Decimal Deferred, 
                                   Decimal RecognizedWeighted, Decimal DeferredWeighted, String transDate, Decimal Forecasted, 
                                   Decimal totalForecastedZero, Decimal ForecastedWeighted, Date schDate, Decimal RecognizedCumulative,
                                   Decimal RecognizedWeightedCumulative, Decimal ForecastedCumulative, Decimal ForecastedWeiCummulative) {
            
            //Assigning in wrapper variable
            this.colorCode = colorCode;
            this.colorCodeZero = colorCodeZero;
            this.colorCodeWei = colorCodeWei;
            this.Recognized = Recognized;
            this.Deferred = Deferred;
            this.RecognizedWeighted = RecognizedWeighted;
            this.DeferredWeighted = DeferredWeighted;
            this.transDate = transDate;
            this.Forecasted = Forecasted;
            this.totalForecastedZero = totalForecastedZero;
            this.ForecastedWeighted = ForecastedWeighted;
            this.schDate = schDate;
            this.RecognizedCumulative = RecognizedCumulative;
            this.RecognizedWeightedCumulative = RecognizedWeightedCumulative;
            this.ForecastedCumulative = ForecastedCumulative;
            this.ForecastedWeiCummulative = ForecastedWeiCummulative;
                                       
            //Set color codes on the basis of dates
            this.colorCode = '#006400'; //Dark Green Color
	       	if(this.schDate > Date.today()){
	           this.colorCode = '#0000FF'; //Blue Color
	       	}
	       	this.colorCodeZero = '#FFFFFF'; //White color
	       	this.colorCodeWei = '#FF6600'; //Orange Color
	       	if(this.schDate > Date.today()){
	           this.colorCodeWei = '#FFFF00'; //Yellow Color
	       	}
        }
    } 
    /**
     *  Description     :   class to hold schedule data.
     **/
     public Class RevRecLineItemScheduleWrapper {
     	
     	//Declaration
     	public RevRecOpportunityLineItemSchedule__c schedule {get; set;}
     	public Decimal cumulativeRecognized {get; set;}
        public Decimal recognizedWeiCumulative {get; set;}
        public Decimal forecastedCumulative {get; set;}
     	
     	//Constructor
     	public RevRecLineItemScheduleWrapper(RevRecOpportunityLineItemSchedule__c schedule, Decimal cumulativeRecognized, Decimal recognizedWeiCumulative, Decimal forecastedCumulative) {
     		this.schedule = schedule;
     		this.cumulativeRecognized = cumulativeRecognized;
            this.recognizedWeiCumulative = recognizedWeiCumulative;
            this.forecastedCumulative = forecastedCumulative;
     	}
     }
}