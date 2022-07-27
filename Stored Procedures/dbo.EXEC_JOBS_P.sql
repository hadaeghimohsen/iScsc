SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE PROCEDURE [dbo].[EXEC_JOBS_P]	
   @X XML
AS
BEGIN
   Print 'iScsc Job Run OK';
   /*
   <Job type="RUNATALL">
      <Params justtoday="0" untilbeforeday="3"/>
   </Job>
   */
   
   -- Global Var
   DECLARE @JobType VARCHAR(100) = 'RUNATALL'
   
   SELECT @JobType = @X.query('//Job').value('(Job/@type)[1]' , 'VARCHAR(100)')
   
   -- Local Var
   DECLARE @Mbid BIGINT,
           @ChatId BIGINT,
           @ServFileNo BIGINT,
           @MsgbText NVARCHAR(MAX),
           @JustToDay BIT,
           @UntilBeforeDay INT;
   
   IF @JobType IN ( 'SMSTOAPP', 'RUNATALL' )
   BEGIN 
      SELECT @JustToDay = @X.query('//Params').value('(Params/@justtoday)[1]', 'BIT'),
             @UntilBeforeDay = @X.query('//Params').value('(Params/@untilbeforeday)[1]', 'INT');
             
      -- 1401/04/10 * اولین وظیفه ای که باید انجام شود این هست که پیام هایی که از طریق سامانه پیامکی آماده ارسال بوده اند برای آن دسته از مشتریان که نرم افزار موبایل بله را دارند پیام را ارسال کنیم
      DECLARE C$SmsToApps CURSOR FOR
         SELECT s.MBID, s.CHAT_ID, s.MSGB_TEXT
           FROM dbo.V#Sms_Message_Box s, dbo.Message_Broadcast m
          WHERE s.STAT = '001'
            AND s.VIST_STAT IS NULL
            AND s.CHAT_ID IS NOT NULL
            AND ( 
                  (@JustToDay = 1 AND CAST(s.ACTN_DATE AS DATE) = CAST(GETDATE() AS DATE)) OR 
                  (@JustToDay = 0 AND CAST(s.ACTN_DATE AS DATE) BETWEEN CAST(DATEADD(DAY, @UntilBeforeDay * -1, GETDATE()) AS DATE) AND CAST(GETDATE() AS DATE)) 
                )
            AND s.MSGB_TYPE = m.MSGB_TYPE
            AND m.TELG_STAT = '002';
      
      OPEN [C$SmsToApps];
      L$SmsToApps:
      FETCH [C$SmsToApps] INTO @Mbid, @ChatId, @MsgbText;
      
      IF @@FETCH_STATUS <> 0
         GOTO L$EndSmsToApps;
      
      SELECT @ServFileNo = SERV_FILE_NO
        FROM iRoboTech.dbo.Service_Robot
       WHERE ROBO_RBID = 391
         AND CHAT_ID = @ChatId;
      
      EXEC iRoboTech.dbo.INS_SRRM_P @SRBT_SERV_FILE_NO = @ServFileNo, @SRBT_ROBO_RBID = 391, @RWNO = 0, @SRMG_RWNO = NULL, @Ordt_Ordr_Code = NULL, @Ordt_Rwno = NULL, 
      @MESG_TEXT = @MsgbText, @FILE_ID = NULL,@FILE_PATH = NULL, @MESG_TYPE = '001', @LAT = NULL,@LON = NULL, @CONT_CELL_PHON = NULL;
      
      GOTO L$SmsToApps;
      L$EndSmsToApps:
      CLOSE [C$SmsToApps];
      DEALLOCATE [C$SmsToApps];
   END; 
END;
GO
