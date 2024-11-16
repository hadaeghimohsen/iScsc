SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[CRET_MBSS_P]
	-- Add the parameters for the stored procedure here
	@X XML
AS
BEGIN
	BEGIN TRY
	BEGIN TRAN L$CRET_MBSS_P
	
	-- Procedure Parameters
	DECLARE @RqroRqstRqid BIGINT,	
	        @RqroRwno SMALLINT,
	        @FileNo BIGINT,
	        @Rwno SMALLINT,
	        @RectCode VARCHAR(3),
	        @StrtDate DATE,
	        @EndDate DATE,
	        @AttnNumb INT,
	        @CbmtCode BIGINT;
	        
	-- Init Parameters	
	SELECT @RqroRqstRqid = @X.query('//Param').value('(Param/@rqrorqstrqid)[1]', 'BIGINT'),
	       @RqroRwno = @X.query('//Param').value('(Param/@rqrorwno)[1]', 'SMALLINT'),
	       @FileNo = @X.query('//Param').value('(Param/@fileno)[1]', 'BIGINT'),
	       @Rwno = @X.query('//Param').value('(Param/@rwno)[1]', 'SMALLINT'),
	       @RectCode = @X.query('//Param').value('(Param/@rectcode)[1]', 'VARCHAR(3)'),
	       @StrtDate = @X.query('//Param').value('(Param/@strtdate)[1]', 'DATE'),
	       @EndDate = @X.query('//Param').value('(Param/@enddate)[1]', 'DATE'),
	       @AttnNumb = @X.query('//Param').value('(Param/@attnnumb)[1]', 'INT'),
	       @CbmtCode = @X.query('//Param').value('(Param/@cbmtcode)[1]', 'BIGINT');
	
	-- Procedure Vars
	DECLARE @GapNumb INT, 
	        @i INT = 1,
	        @SesnDate DATE = @StrtDate;
	-- Init Vars
	SELECT @GapNumb = CAST(DATEDIFF(DAY, @StrtDate, @EndDate) / @AttnNumb AS INT);
	
	-- First delete old records
	DELETE dbo.Member_Ship_Session 
	 WHERE RQRO_RQST_RQID = @RqroRqstRqid 
	   AND RQRO_RWNO = @RqroRwno 
	   AND MBSP_FIGH_FILE_NO = @FileNo 
	   AND MBSP_RWNO = @Rwno;
	
	WHILE (@i <= @AttnNumb)
	BEGIN
	   INSERT INTO dbo.Member_Ship_Session ( RQRO_RQST_RQID, RQRO_RWNO, MBSP_FIGH_FILE_NO, MBSP_RWNO ,MBSP_RECT_CODE ,CODE ,SESN_DATE )
	   VALUES (@RqroRqstRqid, @RqroRwno, @FileNo, @Rwno, @RectCode, 0, @SesnDate);
	   
	   -- Init session date
	   SELECT @SesnDate = DATEADD(DAY, @GapNumb, @SesnDate);
	   
	   L$Loop:
	   -- Check valid date	   
	   IF EXISTS (SELECT * FROM dbo.Holidays h WHERE h.HLDY_DATE = @SesnDate) OR
	      NOT EXISTS(SELECT * FROM dbo.Club_Method_Weekday a 
	                  WHERE a.CBMT_CODE = @CbmtCode
	                    AND a.STAT = '002' 
	                    AND a.WEEK_DAY = dbo.GET_PSTR_U(DATEPART(WEEKDAY, @SesnDate), 3)
	      )
	   BEGIN
	      SELECT @SesnDate = DATEADD(DAY, 1, @SesnDate);
	      GOTO L$Loop;
	   END	   
	   
	   SET @i += 1;
	END	
	
	COMMIT TRAN [L$CRET_MBSS_P]	
	END TRY
	BEGIN CATCH
	   DECLARE @ErrorMessage NVARCHAR(MAX) = ERROR_MESSAGE();
      RAISERROR ( @ErrorMessage, -- Message text.
               16, -- Severity.
               1 -- State.
               );
      ROLLBACK TRAN [L$CRET_MBSS_P];
	END CATCH
END
GO
