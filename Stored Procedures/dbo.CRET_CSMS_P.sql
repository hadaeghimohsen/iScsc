SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[CRET_CSMS_P]
	-- Add the parameters for the stored procedure here
	@X XML
AS
BEGIN
   DECLARE @XData XML
          ,@LineType VARCHAR(3)
          ,@SubSys int
          ,@InsrFnamStat VARCHAR(3)
          ,@InsrCnamStat VARCHAR(3)
          ,@ClubCode BIGINT
          ,@ClubName NVARCHAR(250)
          ,@MsgbText NVARCHAR(MAX)
          ,@DebtPric BIGINT
          ,@AmntType VARCHAR(3)
          ,@AmntTypeDesc NVARCHAR(255);
          
   /*
   <Process>
	   <Contacts subsys="" linetype="">
	      <Contact phonnumb="">
	         <Message type="">TextMessage</Message>
	      </Contact>
	   </Contacts>
	</Process>
   */
   
   --SET @MsgbText =                               
   --   dbo.GET_TEXT_F(
   --      (SELECT @FileNo AS '@fileno'
   --            ,1 AS '@mbsprwno'
   --            ,@MsgbText AS '@text'
   --         FOR XML PATH('TemplateToText'))).query('Result').value('.', 'NVARCHAR(4000)');
                           
   -- تبریک تولد 
	IF EXISTS (SELECT * FROM Message_Broadcast WHERE MSGB_TYPE IN ('001') AND STAT = '002' )
	BEGIN
	   SELECT @LineType = LINE_TYPE
	         ,@SubSys = 5
	         ,@InsrFnamStat = INSR_FNAM_STAT
	         ,@InsrCnamStat = INSR_CNAM_STAT
	         ,@ClubCode = CLUB_CODE
	         ,@ClubName = CASE WHEN CLUB_CODE IS NULL OR NOT EXISTS(SELECT * FROM Club WHERE Code = CLUB_CODE) THEN ISNULL(CLUB_NAME, '') ELSE (SELECT NAME FROM Club WHERE CODE = CLUB_CODE) END
	         ,@MsgbText = MSGB_TEXT
	     FROM Message_Broadcast
	    WHERE MSGB_TYPE = '001'
	      AND STAT = '002';
	   
	   SELECT @XData = (	      
	      SELECT @SubSys AS '@subsys'
	            ,@LineType AS '@linetype'
	            ,CELL_PHON_DNRM AS 'Contact/@phonnumb'
	            ,'001' AS 'Contact/Message/@type'
	            ,/*CASE @InsrFnamStat WHEN '002' THEN CASE SEX_TYPE_DNRM WHEN '001' THEN N'آقای ' ELSE N'سرکارخانم ' END + NAME_DNRM + CHAR(13) ELSE '' END + 
	             @MsgbText*/
	             dbo.GET_TEXT_F(
                  (SELECT FILE_NO AS '@fileno'                        
                         ,@MsgbText AS '@text'
                      FOR XML PATH('TemplateToText'))).query('Result').value('.', 'NVARCHAR(4000)') + CHAR(13) +
	             CASE @InsrCnamStat WHEN '002' THEN @ClubName ELSE N'' END AS 'Contact/Message'	          
	        FROM Fighter
	       WHERE CONF_STAT = '002'
	         AND BRTH_DATE_DNRM IS NOT NULL
	         AND CELL_PHON_DNRM IS NOT NULL
	         AND ACTV_TAG_DNRM >= '101'
	         AND DATEDIFF(YEAR, BRTH_DATE_DNRM, GETDATE()) > 2 -- حداقل سن دو سال رو داشته باشد
	         AND SUBSTRING(dbo.GET_MTOS_U(BRTH_DATE_DNRM), 6, 2) = SUBSTRING(dbo.GET_MTOS_U(GETDATE()), 6, 2)
	         AND SUBSTRING(dbo.GET_MTOS_U(BRTH_DATE_DNRM), 9, 2) = SUBSTRING(dbo.GET_MTOS_U(GETDATE()), 9, 2)
	         /*AND DATEPART(D, BRTH_DATE_DNRM) = DATEPART(D, GETDATE())
	         AND DATEPART(M, BRTH_DATE_DNRM) = DATEPART(M, GETDATE())*/
	         AND NOT EXISTS (
	             SELECT *
	               FROM iProject.Msgb.Sms_Message_Box
	              WHERE SUB_SYS = 5
	                AND MSGB_TYPE = '001'
	                AND PHON_NUMB = CELL_PHON_DNRM
	                AND CAST(ACTN_DATE AS DATE) = CAST(GETDATE() AS DATE)
	         )
	         FOR XML PATH('Contacts'), ROOT('Process')
	  );
	  
	  -- گام اول تبریک به خود فرد
	  EXEC iProject.[Msgb].PrepareSendSms @X = @XData;
	  
	  
	  SELECT @XData = (	      
	      SELECT @SubSys AS '@subsys'
	            ,@LineType AS '@linetype'
	            ,MOM_CELL_PHON_DNRM AS 'Contact/@phonnumb'
	            ,'001' AS 'Contact/Message/@type'
	            ,N'مادر ' + CASE SEX_TYPE_DNRM WHEN '001' THEN (N'آقا ' + FRST_NAME_DNRM) ELSE ( FRST_NAME_DNRM + N' خانم' ) END + CHAR(13) + 
	             N'تولد دلبندتان را به شما تبریک می گوییم.' + CHAR(13) + N' با آرزوی سلامتی و شاد کامی برای شما خانواده ' + LAST_NAME_DNRM + N' عزیز' + CHAR(10) + CHAR(10) +
	             CASE @InsrCnamStat WHEN '002' THEN @ClubName ELSE N'' END AS 'Contact/Message'	          
	        FROM Fighter
	       WHERE CONF_STAT = '002'
	         AND BRTH_DATE_DNRM IS NOT NULL
	         AND MOM_CELL_PHON_DNRM IS NOT NULL
	         AND ACTV_TAG_DNRM >= '101'
	         AND DATEDIFF(YEAR, BRTH_DATE_DNRM, GETDATE()) > 2 -- حداقل سن دو سال رو داشته باشد
	         AND SUBSTRING(dbo.GET_MTOS_U(BRTH_DATE_DNRM), 6, 2) = SUBSTRING(dbo.GET_MTOS_U(GETDATE()), 6, 2)
	         AND SUBSTRING(dbo.GET_MTOS_U(BRTH_DATE_DNRM), 9, 2) = SUBSTRING(dbo.GET_MTOS_U(GETDATE()), 9, 2)
	         /*AND DATEPART(D, BRTH_DATE_DNRM) = DATEPART(D, GETDATE())
	         AND DATEPART(M, BRTH_DATE_DNRM) = DATEPART(M, GETDATE())*/
	         AND NOT EXISTS (
	             SELECT *
	               FROM iProject.Msgb.Sms_Message_Box
	              WHERE SUB_SYS = 5
	                AND MSGB_TYPE = '001'
	                AND PHON_NUMB = MOM_CELL_PHON_DNRM
	                AND CAST(ACTN_DATE AS DATE) = CAST(GETDATE() AS DATE)
	         )
	         FOR XML PATH('Contacts'), ROOT('Process')
	  );
	  
	  -- گام دوم تبریک به مادر فرد
	  EXEC iProject.[Msgb].PrepareSendSms @X = @XData;
	  
	  
	  SELECT @XData = (	      
	      SELECT @SubSys AS '@subsys'
	            ,@LineType AS '@linetype'
	            ,DAD_CELL_PHON_DNRM AS 'Contact/@phonnumb'
	            ,'001' AS 'Contact/Message/@type'
	            ,N'پدر ' + CASE SEX_TYPE_DNRM WHEN '001' THEN (N'آقا ' + FRST_NAME_DNRM) ELSE ( FRST_NAME_DNRM + N' خانم' ) END + CHAR(13) + 
	             N'تولد دلبندتان را به شما تبریک می گوییم.' + CHAR(13) + N' با آرزوی سلامتی و شاد کامی برای شما خانواده '  + LAST_NAME_DNRM + N' عزیز' + CHAR(10) + CHAR(10) +
	             CASE @InsrCnamStat WHEN '002' THEN @ClubName ELSE N'' END AS 'Contact/Message'	          
	        FROM Fighter
	       WHERE CONF_STAT = '002'
	         AND BRTH_DATE_DNRM IS NOT NULL
	         AND DAD_CELL_PHON_DNRM IS NOT NULL
	         AND ACTV_TAG_DNRM >= '101'
	         AND DATEDIFF(YEAR, BRTH_DATE_DNRM, GETDATE()) > 2 -- حداقل سن دو سال رو داشته باشد
	         AND SUBSTRING(dbo.GET_MTOS_U(BRTH_DATE_DNRM), 6, 2) = SUBSTRING(dbo.GET_MTOS_U(GETDATE()), 6, 2)
	         AND SUBSTRING(dbo.GET_MTOS_U(BRTH_DATE_DNRM), 9, 2) = SUBSTRING(dbo.GET_MTOS_U(GETDATE()), 9, 2)
	         /*AND DATEPART(D, BRTH_DATE_DNRM) = DATEPART(D, GETDATE())
	         AND DATEPART(M, BRTH_DATE_DNRM) = DATEPART(M, GETDATE())*/
	         AND NOT EXISTS (
	             SELECT *
	               FROM iProject.Msgb.Sms_Message_Box
	              WHERE SUB_SYS = 5
	                AND MSGB_TYPE = '001'
	                AND PHON_NUMB = DAD_CELL_PHON_DNRM
	                AND CAST(ACTN_DATE AS DATE) = CAST(GETDATE() AS DATE)
	         )
	         FOR XML PATH('Contacts'), ROOT('Process')
	  );
	  
	  -- گام دوم تبریک به پدر فرد
	  EXEC iProject.[Msgb].PrepareSendSms @X = @XData;
	END
	--------------------------*********************************
	--------------------------*********************************	
	-- مانده بدهی فرد
	IF EXISTS (SELECT * FROM Message_Broadcast WHERE MSGB_TYPE IN ('002') AND STAT = '002' )
	BEGIN
	   SELECT @LineType = LINE_TYPE
	         ,@SubSys = 5
	         ,@InsrFnamStat = INSR_FNAM_STAT
	         ,@InsrCnamStat = INSR_CNAM_STAT
	         ,@ClubCode = CLUB_CODE
	         ,@ClubName = CASE WHEN CLUB_CODE IS NULL OR NOT EXISTS(SELECT * FROM Club WHERE Code = CLUB_CODE) THEN ISNULL(CLUB_NAME, '') ELSE (SELECT NAME FROM Club WHERE CODE = CLUB_CODE) END
	         ,@MsgbText = MSGB_TEXT
	         ,@DebtPric = DEBT_PRIC
	     FROM Message_Broadcast
	    WHERE MSGB_TYPE = '002'
	      AND STAT = '002';
	   
	   
	   SELECT @AmntType = rg.AMNT_TYPE, 
	          @AmntTypeDesc = d.DOMN_DESC
	     FROM iScsc.dbo.Regulation rg, iScsc.dbo.[D$ATYP] d
	    WHERE rg.TYPE = '001'
	      AND rg.REGL_STAT = '002'
	      AND rg.AMNT_TYPE = d.VALU;
	   
	   SELECT @XData = (	      
	      SELECT @SubSys AS '@subsys'
	            ,@LineType AS '@linetype'
	            ,CELL_PHON_DNRM AS 'Contact/@phonnumb'
	            ,'002' AS 'Contact/Message/@type'
	            ,/*CASE @InsrFnamStat WHEN '002' THEN CASE SEX_TYPE_DNRM WHEN '001' THEN N'آقای ' ELSE N'سرکارخانم ' END + NAME_DNRM + CHAR(13) ELSE N' ' END + 
	             @MsgbText + CHAR(13) + N'جمع مبلغ بدهی شما ' + REPLACE(CONVERT(NVARCHAR, CONVERT(MONEY, DEBT_DNRM), 1), '.00', '') + N' ' + @AmntTypeDesc + N' '*/
	             dbo.GET_TEXT_F(
                  (SELECT FILE_NO AS '@fileno'                        
                         ,@MsgbText AS '@text'
                      FOR XML PATH('TemplateToText'))).query('Result').value('.', 'NVARCHAR(4000)') + CHAR(13) + + N'جمع مبلغ بدهی شما ' + REPLACE(CONVERT(NVARCHAR, CONVERT(MONEY, DEBT_DNRM), 1), '.00', '') + N' ' + @AmntTypeDesc + CHAR(13) + 
	             CASE @InsrCnamStat WHEN '002' THEN @ClubName ELSE N'' END AS 'Contact/Message'
	        FROM Fighter
	       WHERE CONF_STAT = '002'
	         AND CELL_PHON_DNRM IS NOT NULL
	         AND ACTV_TAG_DNRM >= '101'
	         AND DEBT_DNRM >= @DebtPric
	         AND NOT EXISTS (
	             SELECT *
	               FROM iProject.Msgb.Sms_Message_Box
	              WHERE SUB_SYS = 5
	                AND MSGB_TYPE = '002'
	                AND PHON_NUMB = CELL_PHON_DNRM
	                AND CAST(ACTN_DATE AS DATE) BETWEEN CAST(DATEADD(DAY, -4, GETDATE()) AS DATE) AND CAST(GETDATE() AS DATE)
	         )
	         FOR XML PATH('Contacts'), ROOT('Process')
	  );
	  
	  -- گام اول تبریک به خود فرد
	  EXEC iProject.[Msgb].PrepareSendSms @X = @XData;
	  
	  
	  SELECT @XData = (	      
	      SELECT @SubSys AS '@subsys'
	            ,@LineType AS '@linetype'
	            ,MOM_CELL_PHON_DNRM AS 'Contact/@phonnumb'
	            ,'002' AS 'Contact/Message/@type'
	            ,N'مادر ' + CASE SEX_TYPE_DNRM WHEN '001' THEN (N'آقا ' + FRST_NAME_DNRM) ELSE ( FRST_NAME_DNRM + N' خانم' ) END + CHAR(13) + 
	             N'مبلغ بدهی فرزند شما ' + REPLACE(CONVERT(NVARCHAR, CONVERT(MONEY, DEBT_DNRM), 1), '.00', '') + N' ' + @AmntTypeDesc + CHAR(13) + N' لطفا جهت پرداخت بدهی تا ظرف 2 روز آینده اقدام فرمایید. با تشکر از شما خانواده ' + LAST_NAME_DNRM + N' عزیز' + CHAR(10) + CHAR(10) +
	             CASE @InsrCnamStat WHEN '002' THEN @ClubName ELSE N'' END AS 'Contact/Message'	          
	        FROM Fighter
	       WHERE CONF_STAT = '002'
	         AND MOM_CELL_PHON_DNRM IS NOT NULL
	         AND ACTV_TAG_DNRM >= '101'
	         AND DEBT_DNRM >= @DebtPric
	         AND NOT EXISTS (
	             SELECT *
	               FROM iProject.Msgb.Sms_Message_Box
	              WHERE SUB_SYS = 5
	                AND MSGB_TYPE = '002'
	                AND PHON_NUMB = MOM_CELL_PHON_DNRM
	                AND CAST(ACTN_DATE AS DATE) BETWEEN CAST(DATEADD(DAY, -4, GETDATE()) AS DATE) AND CAST(GETDATE() AS DATE)
	         )
	         FOR XML PATH('Contacts'), ROOT('Process')
	  );
	  
	  -- گام دوم تبریک به مادر فرد
	  EXEC iProject.[Msgb].PrepareSendSms @X = @XData;
	  
	  
	  SELECT @XData = (	      
	      SELECT @SubSys AS '@subsys'
	            ,@LineType AS '@linetype'
	            ,DAD_CELL_PHON_DNRM AS 'Contact/@phonnumb'
	            ,'002' AS 'Contact/Message/@type'
	            ,N'پدر ' + CASE SEX_TYPE_DNRM WHEN '001' THEN (N'آقا ' + FRST_NAME_DNRM) ELSE ( FRST_NAME_DNRM + N' خانم' ) END + CHAR(13) + 
	             N'مبلغ بدهی فرزند شما ' + REPLACE(CONVERT(NVARCHAR, CONVERT(MONEY, DEBT_DNRM), 1), '.00', '') + N' ' + @AmntTypeDesc + CHAR(13) + N' لطفا جهت پرداخت بدهی تا ظرف 2 روز آینده اقدام فرمایید. با تشکر از شما خانواده ' + LAST_NAME_DNRM + N' عزیز' + CHAR(10) + CHAR(10) +
	             CASE @InsrCnamStat WHEN '002' THEN @ClubName ELSE N'' END AS 'Contact/Message'	          
	        FROM Fighter
	       WHERE CONF_STAT = '002'
	         AND DAD_CELL_PHON_DNRM IS NOT NULL
	         AND ACTV_TAG_DNRM >= '101'
	         AND DEBT_DNRM >= @DebtPric
	         AND NOT EXISTS (
	             SELECT *
	               FROM iProject.Msgb.Sms_Message_Box
	              WHERE SUB_SYS = 5
	                AND MSGB_TYPE = '002'
	                AND PHON_NUMB = DAD_CELL_PHON_DNRM
	                AND CAST(ACTN_DATE AS DATE) BETWEEN CAST(DATEADD(DAY, -4, GETDATE()) AS DATE) AND CAST(GETDATE() AS DATE)
	         )
	         FOR XML PATH('Contacts'), ROOT('Process')
	  );
	  
	  -- گام دوم تبریک به پدر فرد
	  EXEC iProject.[Msgb].PrepareSendSms @X = @XData;
	END
END
GO
