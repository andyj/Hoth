﻿/** A logging object used during development. **/
component 
implements="Hoth.object.loggers.ILogger" 
{	
	public function init(required Config)
	{		
		variables.Config = arguments.Config;
		
		variables.startTick = getTickCount();
		variables.messages = ['Logger Created at #dateFormat(now(),'long')# #timeFormat(now(),'long')#'];
		variables.timers = [variables.startTick];
				
		info(this,'URL: #cgi.HTTP_HOST##cgi.PATH_INFO#');
		
		return this;
	}
	
	public function info(required cfc,required string message,details='')
	{
		recordTime();
		local.detail = (isSimpleValue(arguments.details)) ? arguments.details : serializeJSON(arguments.details);
		arrayAppend(variables.messages, "INFO: '#getCFCPath(arguments.cfc)#' '#arguments.message#'|'#local.detail#'");
		return;		
	}
	
	public function warn(required cfc,required string message,details='')
	{
		recordTime();
		local.detail = (isSimpleValue(arguments.details)) ? arguments.details : serializeJSON(arguments.details);
		arrayAppend(variables.messages, "WARN: '#getCFCPath(arguments.cfc)#' '#arguments.message#'|'#local.detail#''");
		
		try {
			throw(message='Purposeful Throw');
		} catch (any e) {
			local.HothTracker = (structKeyExists(application, 'HothTracker'))
				? application.HothTracker
				: new Hoth.HothTracker( new atvcms.config.HothConfig() );
			local.Hoth = local.HothTracker.track(e);
			info(cfc=arguments.cfc,message='Hoth generated by warn #local.Hoth#');
		}
		return;		
	}
	
	public function flush()
	{	
		if (structKeyExists(variables.Config, 'flush'))
		{
			local.result = variables.Config.flush();
			
			if (!isNull(local.result))
			{
				return;
			}
		}
		
		info(this,'Flushing Log');
		local.n = arrayLen(variables.timers);
		local.output = ["Elapsed Time: xxxxxx; #variables.messages[1]#"];
		local.previousTime = variables.timers[1];
		for(local.i=2;local.i<=local.n;local.i++)        
		{        
			arrayAppend(local.output, "Elapsed Time: #numberFormat(variables.timers[local.i] - local.previousTime,"000000")#; #variables.messages[local.i]#");
			local.previousTime = variables.timers[local.i];
		}
		arrayAppend(local.output, 'Total Request Time was : #getTickCount() - variables.startTick#ms.');
		arrayAppend(local.output, '-----------------------------------------');
		
		if (!fileExists(expandPath('/atvlogs/request_debugging.log')))
		{
			application.cbController.getPlugin('FileUtils')
				.appendFile(expandPath('/atvlogs/request_debugging.log'), 'Elapsed Time;Message (Test|Detail|CFC)');
		}
		
		application.cbController.getPlugin('FileUtils')
			.appendFile(expandPath('/atvlogs/request_debugging.log'), arrayToList(local.output, chr(10)));
		
		return;
	}
	
	private function getCFCPath(cfc) {
		return getMetaData(arguments.cfc).fullname;
	}
	
	private function recordTime() {
		arrayAppend(variables.timers, getTickCount());
	}
}