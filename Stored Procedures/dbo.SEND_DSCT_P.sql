SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[SEND_DSCT_P]
	-- Add the parameters for the stored procedure here
	@X XML
AS
BEGIN
	BEGIN TRY
	BEGIN TRAN T$SEND_DSCT_P
	   DECLARE @AdvpCode BIGINT,
	           @Tmid BIGINT,
	           @SendSmsStat BIT,
	           @SendAppStat BIT;
	   
	   SELECT @AdvpCode = @x.query('//Advertising_Parameter').value('(Advertising_Parameter/@code)[1]' ,'BIGINT'),
	          @Tmid = @x.query('//Advertising_Parameter').value('(Advertising_Parameter/@tmid)[1]' ,'BIGINT'),
	          @SendSmsStat = @x.query('//Advertising_Parameter').value('(Advertising_Parameter/@sendsmsstat)[1]' ,'BIT'),
	          @SendAppStat = @x.query('//Advertising_Parameter').value('(Advertising_Parameter/@sendappstat)[1]' ,'BIT');
	   
      -- Local Var
      DECLARE @Code BIGINT,
              @FileNo BIGINT,
              @CellPhon VARCHAR(11),
              @MsgbText NVARCHAR(MAX),
              @LineType VARCHAR(3) = '001';

	   DECLARE C$Advc CURSOR FOR
	      SELECT a.CODE, a.FIGH_FILE_NO, a.CELL_PHON
	        FROM dbo.Advertising_Campaign a
	       WHERE a.ADVP_CODE = @AdvpCode;
	    
	   OPEN [C$Advc];
	   L$C$ADVC$LOOP:
	   FETCH [C$Advc] INTO @Code, @FileNo, @CellPhon;
	   IF @@FETCH_STATUS <> 0
	      GOTO L$C$ADVC$ENDLOOP;
	   
	   -- 1401/05/15 * ثبت کد تخفیف مشتریان
	   IF @FileNo IS NOT NULL
	   BEGIN	   
	      MERGE dbo.Fighter_Discount_Card T
	      USING (SELECT p.RECD_TYPE,
	                    p.EXPR_DATE,
	                    p.DISC_CODE,
	                    p.DSCT_TYPE,
	                    p.DSCT_AMNT,
	                    p.ADVP_NAME,
	                    p.TEMP_TMID,
	                    p.MTOD_CODE,
	                    p.CTGY_CODE,
	                    p.RQTP_CODE
	               FROM dbo.Advertising_Parameter p 
	              WHERE p.CODE = @AdvpCode) S
	      ON (t.FIGH_FILE_NO = @FileNo AND
	          T.RECD_TYPE = S.RECD_TYPE AND 
	          t.RQST_RQID IS NULL AND 
	          CAST(T.EXPR_DATE AS DATE) >= CAST(GETDATE() AS DATE))
	      WHEN NOT MATCHED THEN 
	         INSERT (ADVP_CODE, FIGH_FILE_NO, CODE, RECD_TYPE, DISC_CODE, EXPR_DATE, STAT, MTOD_CODE, CTGY_CODE, RQTP_CODE, DSCT_AMNT, DSCT_TYPE, DSCT_DESC, TEMP_TMID)
	         VALUES (@AdvpCode, @FileNo, 0, s.RECD_TYPE, s.DISC_CODE, s.EXPR_DATE, '002', s.MTOD_CODE, s.CTGY_CODE, s.RQTP_CODE, s.DSCT_AMNT, s.DSCT_TYPE, s.ADVP_NAME, @Tmid);
	   END
	   
	   -- IF Send Notification SMS
	   IF @SendSmsStat = 1
	   BEGIN
	      -- 1401/03/28
         SET @MsgbText =                               
               dbo.GET_TEXT_F(
                  (SELECT @FileNo AS '@fileno'
                         ,@AdvpCode AS '@advpcode'
                         ,@Tmid AS '@tmid'
                     FOR XML PATH('TemplateToText'))).query('Result').value('.', 'NVARCHAR(4000)');
         
         DECLARE @XMsg XML;
         SELECT @XMsg = (
            SELECT 5 AS '@subsys',
                   @LineType AS '@linetype',
                   (
                     SELECT @CellPhon AS '@phonnumb',
                            (
                                SELECT '005' AS '@type' 
                                       ,@Code AS '@rfid'
                                       ,@MsgbText
                                   FOR XML PATH('Message'), TYPE 
                            ) 
                        FOR XML PATH('Contact'), TYPE
                   )
              FOR XML PATH('Contacts'), ROOT('Process')                            
         );
         EXEC dbo.MSG_SEND_P @X = @XMsg -- xml
	   END;
	   
	   -- IF Send Notification App
	   IF @SendAppStat = 1
	   BEGIN
	      PRINT 'Save Record in APP List';	      
	   END;
	   
	   -- 1401/05/14 * بروزرسانی اطلاعات جدول کمپین
	   UPDATE dbo.Advertising_Campaign SET RECD_STAT = '003', ACTN_DATE = GETDATE() WHERE ADVP_CODE = @AdvpCode AND CODE = @Code;
	      
	   GOTO L$C$ADVC$LOOP;
	   L$C$ADVC$ENDLOOP:
	   CLOSE [C$Advc];
	   DEALLOCATE [C$Advc];
	   
	COMMIT TRAN [T$SEND_DSCT_P]
	END TRY
	BEGIN CATCH
	   DECLARE @ErrorMessage NVARCHAR(MAX) = ERROR_MESSAGE();
      RAISERROR ( @ErrorMessage, -- Message text.
               16, -- Severity.
               1 -- State.
               );
      ROLLBACK TRAN [T$SEND_DSCT_P];
	END CATCH
END
GO
