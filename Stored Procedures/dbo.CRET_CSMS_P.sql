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
          ,@MsgbText NVARCHAR(MAX);
          
   /*
   <Process>
	   <Contacts subsys="" linetype="">
	      <Contact phonnumb="">
	         <Message type="">TextMessage</Message>
	      </Contact>
	   </Contacts>
	</Process>
   */
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
	            ,CASE @InsrFnamStat WHEN '002' THEN CASE SEX_TYPE_DNRM WHEN '001' THEN N'آقای ' ELSE N'سرکارخانم ' END + NAME_DNRM + CHAR(13) ELSE '' END + 
	             @MsgbText + CHAR(13) +
	             CASE @InsrCnamStat WHEN '002' THEN @ClubName END AS 'Contact/Message'	          
	        FROM Fighter
	       WHERE CONF_STAT = '002'
	         AND BRTH_DATE_DNRM IS NOT NULL
	         AND CELL_PHON_DNRM IS NOT NULL
	         AND ACTV_TAG_DNRM >= '101'
	         AND DATEPART(D, BRTH_DATE_DNRM) = DATEPART(D, GETDATE())
	         AND DATEPART(M, BRTH_DATE_DNRM) = DATEPART(M, GETDATE())
	         FOR XML PATH('Contacts'), ROOT('Process')
	  );
	END	
	
	EXEC iProject.[Msgb].PrepareSendSms @X = @XData;
END
GO
