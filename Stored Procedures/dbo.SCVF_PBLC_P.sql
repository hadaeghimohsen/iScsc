SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[SCVF_PBLC_P]
	@X XML
AS
BEGIN
	BEGIN TRY
	   BEGIN TRAN [T$SAVE_FAST_P]
   	
   	DECLARE @FileNo BIGINT,
   	        @CellPhon VARCHAR(11),
   	        @TellPhon VARCHAR(11),
   	        @DadCellPhon VARCHAR(11),
   	        @MomCellPhon VARCHAR(11),   	        
   	        @SuntCode VARCHAR(4),
   	        @GlobCode NVARCHAR(50),
   	        @ServNo NVARCHAR(50),
   	        @NatlCode VARCHAR(10),
   	        @InsrDate DATE,
   	        @ChatId BIGINT,
   	        @DadChatId BIGINT,
   	        @MomChatId BIGINT,
   	        @FngrPrnt VARCHAR(20);
   	
   	-- مقدار دهی متغییر ها
   	SELECT @FileNo = @x.query('//Fighter').value('(Fighter/@fileno)[1]', 'BIGINT'),
   	       @CellPhon = @x.query('//Fighter').value('(Fighter/@cellphon)[1]', 'VARCHAR(11)'),
   	       @TellPhon = @x.query('//Fighter').value('(Fighter/@tellphon)[1]', 'VARCHAR(11)'),
   	       @DadCellPhon = @x.query('//Fighter').value('(Fighter/@dadcellphon)[1]', 'VARCHAR(11)'),
   	       @MomCellPhon = @x.query('//Fighter').value('(Fighter/@momcellphon)[1]', 'VARCHAR(11)'),
   	       @SuntCode = @x.query('//Fighter').value('(Fighter/@suntcode)[1]', 'VARCHAR(4)'),
   	       @GlobCode = @x.query('//Fighter').value('(Fighter/@globcode)[1]', 'NVARCHAR(50)'),
   	       @ServNo = @x.query('//Fighter').value('(Fighter/@servno)[1]', 'NVARCHAR(50)'),
   	       @NatlCode = @x.query('//Fighter').value('(Fighter/@natlcode)[1]', 'VARCHAR(10)'),
   	       @InsrDate = @x.query('//Fighter').value('(Fighter/@insrdate)[1]', 'DATE'),
   	       @ChatId = @x.query('//Fighter').value('(Fighter/@chatid)[1]', 'BIGINT'),
   	       @DadChatId = @x.query('//Fighter').value('(Fighter/@dadchatid)[1]', 'BIGINT'),
   	       @MomChatId = @x.query('//Fighter').value('(Fighter/@momchatid)[1]', 'BIGINT'),
   	       @FngrPrnt = @x.query('//Fighter').value('(Fighter/@fngrprnt)[1]', 'VARCHAR(20)');
   	
   	IF @ChatId = 0 SET @ChatId = NULL;
   	IF @DadChatId = 0 SET @DadChatId = NULL;
   	IF @MomChatId = 0 SET @MomChatId = NULL;
   	IF LEN(@FngrPrnt) = 0 SET @FngrPrnt = NULL;
   	
   	-- Local Var
   	DECLARE @Rqid BIGINT,
	           @RegnCode VARCHAR(3),
	           @PrvnCode VARCHAR(3);
   	
   	-- اگر اطلاعاتی که میخواهیم تغییر دهیم با درون پایگاه داده نباشد و نیازی به ثبت درخواست نبلشد بروزرسانی انجام میدهیم   	   	       
   	IF @FileNo = 0 OR @FileNo IS NULL BEGIN RAISERROR(N'شماره پرونده برای هنرجو وارد نشده', 16, 1); RETURN; END
      SELECT @RegnCode = Regn_Code, @PrvnCode = Regn_Prvn_Code 
        FROM Fighter
       WHERE FILE_NO = @FileNo;
      
      DECLARE @Xt XML;
      SELECT @Xt = (
         SELECT 0 AS '@rqid'
               ,'002' AS '@rqtpcode'
               ,'004' AS '@rqttcode'
               ,(
                  SELECT @FileNo AS '@fileno'
                     FOR XML PATH('Request_Row'), TYPE
               )
             FOR XML PATH('Request'), ROOT('Process')
      );
      EXECUTE dbo.PBL_RQST_F @X = @Xt -- xml
      
      SELECT @Rqid = R.RQID
        FROM dbo.Request r, dbo.Request_Row Rr, dbo.Fighter f
       WHERE r.RQID = rr.RQST_RQID
         AND rr.FIGH_FILE_NO = f.FILE_NO
         AND r.RQID = f.RQST_RQID
         AND f.FILE_NO = @FileNo
         AND r.RQST_STAT = '001'
         AND r.RQTP_CODE = '002'
         AND r.RQTT_CODE = '004';
      
      UPDATE dbo.Fighter_Public
         SET CELL_PHON = @CellPhon,
             TELL_PHON = @TellPhon,
             DAD_CELL_PHON = @DadCellPhon,
             MOM_CELL_PHON = @MomCellPhon,
             SUNT_CODE = @SuntCode,
             GLOB_CODE = @GlobCode,
             SERV_NO = @ServNo,
             NATL_CODE = @NatlCode,
             INSR_DATE = @InsrDate,
             INSR_NUMB = @NatlCode,
             CHAT_ID = @ChatId,
             DAD_CHAT_ID = @DadChatId,
             MOM_CHAT_ID = @MomChatId,
             FNGR_PRNT = ISNULL(@FngrPrnt, FNGR_PRNT)
       WHERE FIGH_FILE_NO = @FileNo
         AND RQRO_RQST_RQID = @Rqid
         AND RECT_CODE = '001';
      
      SELECT @Xt = (
         SELECT @Rqid AS '@rqid'
               ,@PrvnCode AS '@prvncode'
               ,@RegnCode AS '@regncode'
               ,(
                  SELECT @FileNo AS '@fileno'
                     FOR XML PATH('Request_Row'), TYPE                     
               )
             FOR XML PATH('Request'), ROOT('Process')
      );
      EXECUTE dbo.PBL_SAVE_F @X = @Xt -- xml
        
	   COMMIT TRAN [T$SAVE_FAST_P]	
	END TRY
	BEGIN CATCH
	   DECLARE @ErrorMessage NVARCHAR(4000);
	   SET @ErrorMessage = ERROR_MESSAGE();
      RAISERROR ( @ErrorMessage, -- Message text.
               16, -- Severity.
               1 -- State.
               );
	   ROLLBACK TRAN [T$SAVE_FAST_P]
	END CATCH
END
GO
