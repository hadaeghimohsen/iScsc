SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[MBSP_SCHG_P]
	-- Add the parameters for the stored procedure here
	@X XML
AS
BEGIN
	/*
	   شرایط ارسال داده ها مربوط به جدول درخواست
	   1 - درخواست جدید می باشد و ستون شماره درخواست خالی می باشد
	   2 - درخواست قبلا ثبت شده و ستون شماره درخواست خالی نمی باشد
	*/
	DECLARE @ErrorMessage NVARCHAR(MAX);
	BEGIN TRAN T1;
	BEGIN TRY
	   DECLARE @Rqid     BIGINT,
	           @RqroRwno SMALLINT,	           
   	        @FileNo BIGINT;   	        
   	
	   SELECT @Rqid     = @X.query('//Request').value('(Request/@rqid)[1]'    , 'BIGINT')
	         ,@RqroRwno = @X.query('//Request_Row').value('(Request_Row/@rwno)[1]', 'SMALLINT')
	         ,@FileNo   = @X.query('//Request_Row').value('(Request_Row/@fileno)[1]', 'BIGINT');	         
	   
      DECLARE @StrtDate002 DATE
             ,@EndDate002  DATE
             ,@PrntCont002 SMALLINT
             ,@NumbMontOfer002 INT
             ,@NumbOfAttnMont002 INT
             ,@SumNumbAttnMont002 INT
             ,@AttnDayType002 VARCHAR(3);
     
     DECLARE  @StrtDate004 DATE
             ,@EndDate004  DATE
             ,@PrntCont004 SMALLINT
             ,@NumbMontOfer004 INT
             ,@NumbOfAttnMont004 INT
             ,@SumNumbAttnMont004 INT
             ,@AttnDayType004 VARCHAR(3);
      
      SELECT @StrtDate002 = STRT_DATE
            ,@EndDate002 = END_DATE
            ,@NumbOfAttnMont002 = NUMB_OF_ATTN_MONT
            ,@SumNumbAttnMont002 = SUM_ATTN_MONT_DNRM
        FROM dbo.Member_Ship
       WHERE RQRO_RQST_RQID = @Rqid
         AND RECT_CODE = '002'
         AND FIGH_FILE_NO = @FileNo;
      
      SELECT @StrtDate004 = STRT_DATE
            ,@EndDate004 = END_DATE
            ,@NumbOfAttnMont004 = NUMB_OF_ATTN_MONT
            ,@SumNumbAttnMont004 = SUM_ATTN_MONT_DNRM
        FROM dbo.Member_Ship
       WHERE RQRO_RQST_RQID = @Rqid
         AND RECT_CODE = '004'
         AND FIGH_FILE_NO = @FileNo;
      
      UPDATE dbo.Member_Ship
         SET STRT_DATE = @StrtDate004
            ,END_DATE = @EndDate004
            ,NUMB_OF_ATTN_MONT = @NumbOfAttnMont004
            ,SUM_ATTN_MONT_DNRM = @SumNumbAttnMont004
       WHERE RQRO_RQST_RQID = @Rqid
         AND RECT_CODE = '002';
      
      UPDATE dbo.Member_Ship
         SET STRT_DATE = @StrtDate002
            ,END_DATE = @EndDate002
            ,NUMB_OF_ATTN_MONT = @NumbOfAttnMont002
            ,SUM_ATTN_MONT_DNRM = @SumNumbAttnMont002
       WHERE RQRO_RQST_RQID = @Rqid
         AND RECT_CODE = '004';
         
      COMMIT TRAN T1;
   END TRY
   BEGIN CATCH
      SET @ErrorMessage = ERROR_MESSAGE();
      RAISERROR ( @ErrorMessage, -- Message text.
               16, -- Severity.
               1 -- State.
               );
      ROLLBACK TRAN T1;
   END CATCH; 
END
GO
