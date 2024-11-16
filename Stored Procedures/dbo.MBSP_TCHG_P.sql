SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[MBSP_TCHG_P]
	-- Add the parameters for the stored procedure here
	@X XML
AS
BEGIN
   DECLARE @AP BIT
          ,@AccessString VARCHAR(250);
   SET @AccessString = N'<AP><UserName>' + SUSER_NAME() + '</UserName><Privilege>232</Privilege><Sub_Sys>5</Sub_Sys></AP>';	
   EXEC iProject.dbo.SP_EXECUTESQL N'SELECT @ap = DataGuard.AccessPrivilege(@P1)',N'@P1 ntext, @ap BIT OUTPUT',@AccessString , @ap = @ap output
   IF @AP = 0 
   BEGIN
      RAISERROR ( N'خطا - عدم دسترسی به ردیف 232 سطوح امینتی', -- Message text.
               16, -- Severity.
               1 -- State.
               );
      RETURN;
   END;

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
	   
      DECLARE @StrtDate DATETIME
             ,@EndDate  DATETIME
             ,@PrntCont SMALLINT
             ,@NumbMontOfer INT
             ,@NumbOfAttnMont INT
             ,@SumNumbAttnMont INT
             ,@AttnDayType VARCHAR(3)
             ,@StrtTime TIME(0)
             ,@EndTime TIME(0)
             ,@ResnApbsCode BIGINT
             ,@ResnDesc NVARCHAR(500);
      
      SELECT @StrtDate = r.query('Member_Ship').value('(Member_Ship/@strtdate)[1]', 'DATETIME')
            ,@StrtTime = r.query('Member_Ship').value('(Member_Ship/@strttime)[1]', 'TIME(0)')
            ,@EndDate  = r.query('Member_Ship').value('(Member_Ship/@enddate)[1]',  'DATETIME')
            ,@EndTime  = r.query('Member_Ship').value('(Member_Ship/@endtime)[1]',  'TIME(0)')
            ,@PrntCont = r.query('Member_Ship').value('(Member_Ship/@prntcont)[1]', 'SMALLINT')
            ,@NumbMontOfer = r.query('Member_Ship').value('(Member_Ship/@numbmontofer)[1]', 'INT')            
            ,@NumbOfAttnMont = r.query('Member_Ship').value('(Member_Ship/@numbofattnmont)[1]', 'INT')
            ,@SumNumbAttnMont = r.query('Member_Ship').value('(Member_Ship/@sumnumbattnmont)[1]', 'INT')
            ,@AttnDayTYpe = r.query('Member_Ship').value('(Member_Ship/@attndaytype)[1]', 'VARCHAR(3)')
            ,@ResnApbsCode = r.query('Member_Ship').value('(Member_Ship/@resnapbscode)[1]', 'BIGINT')
            ,@ResnDesc = r.query('Member_Ship').value('(Member_Ship/@resndesc)[1]', 'NVARCHAR(500)')
        FROM @X.nodes('//Request_Row') Rqrv(r)
       WHERE r.query('.').value('(Request_Row/@fileno)[1]', 'BIGINT') = @fileno;
      
      IF CAST(@StrtDate AS DATE) IN ('1900-01-01', '0001-01-01') OR CAST(@EndDate AS DATE) IN ('1900-01-01', '0001-01-01')
      BEGIN
         SET @StrtDate = GETDATE();
         SET @EndDate = DATEADD(day, 30, @StrtDate);
      END
      
      IF @ResnApbsCode = 0 SET @ResnApbsCode = NULL;
      
      -- 1401/07/18 * روز نابودی نظام جمهوری اسلامی ایران هست هوراااا
      SELECT @StrtDate = CAST(@StrtDate AS DATETIME) + CAST(@StrtTime AS DATETIME),
             @EndDate = CAST(@EndDate AS DATETIME) + CAST(@EndTime AS DATETIME);      
      
      DECLARE @CrntStrtDate DATE, @CrntEndDate DATE;
      SELECT @CrntStrtDate = ms.STRT_DATE, @CrntEndDate = ms.END_DATE
        FROM dbo.Member_Ship ms
       WHERE ms.RQRO_RQST_RQID = @Rqid
         AND ms.RECT_CODE = '004';
      
      -- 1403/08/18 * چک کردن دسترسی به اعلام مجدد اصلاح دوره 
      -- آیا اجازه داریم روی درخواستی که اصلاح دوره زده شده دوباره اصلاح دوره اعمال کنیم
      -- نام عملیات : حمله به نگین
      IF (CAST(@StrtDate AS DATE) != @CrntStrtDate OR CAST(@EndDate AS DATE) != @CrntEndDate) AND (SELECT COUNT(*) FROM dbo.[VF$Request_Changing](@FileNo) r WHERE r.RQTP_CODE = '034' AND r.RQST_RQID = @Rqid) >= 1 
      BEGIN      
         SET @AccessString = N'<AP><UserName>' + SUSER_NAME() + '</UserName><Privilege>280</Privilege><Sub_Sys>5</Sub_Sys></AP>';	
         EXEC iProject.dbo.SP_EXECUTESQL N'SELECT @ap = DataGuard.AccessPrivilege(@P1)',N'@P1 ntext, @ap BIT OUTPUT',@AccessString , @ap = @ap output
         IF @AP = 0 
         BEGIN
            RAISERROR ( N'خطا - عدم دسترسی به ردیف 280 سطوح امینتی', -- Message text.
                     16, -- Severity.
                     1 -- State.
                     );
            RETURN;
         END;
      END;
      
      -- 1403/08/18 * چک کردن بازه های تاریخی قابل دسترس
      -- اولین دسترسی چک کردن دسترسی نامحدود
      SET @AccessString = N'<AP><UserName>' + SUSER_NAME() + '</UserName><Privilege>285</Privilege><Sub_Sys>5</Sub_Sys></AP>';	
      EXEC iProject.dbo.SP_EXECUTESQL N'SELECT @ap = DataGuard.AccessPrivilege(@P1)',N'@P1 ntext, @ap BIT OUTPUT',@AccessString , @ap = @ap output
      IF @AP = 0 
      BEGIN
         -- آیا منشی اجازه تغییر تاریخ دوره مشتری را دارد یا خیر
         IF CAST(@StrtDate AS DATE) != @CrntStrtDate
         BEGIN
            SET @AccessString = N'<AP><UserName>' + SUSER_NAME() + '</UserName><Privilege>286</Privilege><Sub_Sys>5</Sub_Sys></AP>';	
            EXEC iProject.dbo.SP_EXECUTESQL N'SELECT @ap = DataGuard.AccessPrivilege(@P1)',N'@P1 ntext, @ap BIT OUTPUT',@AccessString , @ap = @ap OUTPUT
            IF @AP = 0 
            BEGIN
               RAISERROR ( N'خطا - عدم دسترسی به ردیف 286 سطوح امینتی', -- Message text.
                           16, -- Severity.
                           1 -- State.
                         );
               RETURN;
            END;
         END;         
            
         IF @CrntEndDate <= @EndDate AND DATEDIFF(DAY, @CrntEndDate, @EndDate) BETWEEN 1 AND 7
         BEGIN
             SET @AccessString = N'<AP><UserName>' + SUSER_NAME() + '</UserName><Privilege>281</Privilege><Sub_Sys>5</Sub_Sys></AP>';	
             EXEC iProject.dbo.SP_EXECUTESQL N'SELECT @ap = DataGuard.AccessPrivilege(@P1)',N'@P1 ntext, @ap BIT OUTPUT',@AccessString , @ap = @ap OUTPUT
             IF @AP = 0 
             BEGIN
                RAISERROR ( N'خطا - عدم دسترسی به ردیف 281 سطوح امینتی', -- Message text.
                            16, -- Severity.
                            1 -- State.
                          );
                RETURN;
             END;
         END;
         ELSE IF @CrntEndDate <= @EndDate AND DATEDIFF(DAY, @CrntEndDate, @EndDate) BETWEEN 8 AND 15
         BEGIN              
             SET @AccessString = N'<AP><UserName>' + SUSER_NAME() + '</UserName><Privilege>282</Privilege><Sub_Sys>5</Sub_Sys></AP>';	
             EXEC iProject.dbo.SP_EXECUTESQL N'SELECT @ap = DataGuard.AccessPrivilege(@P1)',N'@P1 ntext, @ap BIT OUTPUT',@AccessString , @ap = @ap OUTPUT
             IF @AP = 0 
             BEGIN
                RAISERROR ( N'خطا - عدم دسترسی به ردیف 282 سطوح امینتی', -- Message text.
                            16, -- Severity.
                            1 -- State.
                          );
                RETURN;
             END;
         END;
         ELSE IF @CrntEndDate <= @EndDate AND DATEDIFF(DAY, @CrntEndDate, @EndDate) BETWEEN 16 AND 23 
         BEGIN
             SET @AccessString = N'<AP><UserName>' + SUSER_NAME() + '</UserName><Privilege>283</Privilege><Sub_Sys>5</Sub_Sys></AP>';	
             EXEC iProject.dbo.SP_EXECUTESQL N'SELECT @ap = DataGuard.AccessPrivilege(@P1)',N'@P1 ntext, @ap BIT OUTPUT',@AccessString , @ap = @ap OUTPUT
             IF @AP = 0 
             BEGIN
                RAISERROR ( N'خطا - عدم دسترسی به ردیف 283 سطوح امینتی', -- Message text.
                            16, -- Severity.
                            1 -- State.
                          );
                RETURN;
             END;
         END;
         ELSE IF @CrntEndDate <= @EndDate AND DATEDIFF(DAY, @CrntEndDate, @EndDate) BETWEEN 24 AND 31
         BEGIN         
             SET @AccessString = N'<AP><UserName>' + SUSER_NAME() + '</UserName><Privilege>284</Privilege><Sub_Sys>5</Sub_Sys></AP>';	
             EXEC iProject.dbo.SP_EXECUTESQL N'SELECT @ap = DataGuard.AccessPrivilege(@P1)',N'@P1 ntext, @ap BIT OUTPUT',@AccessString , @ap = @ap OUTPUT
             IF @AP = 0 
             BEGIN
                RAISERROR ( N'خطا - عدم دسترسی به ردیف 284 سطوح امینتی', -- Message text.
                            16, -- Severity.
                            1 -- State.
                          );
                RETURN;
             END;
         END;
         ELSE IF @CrntEndDate <= @EndDate AND DATEDIFF(DAY, @CrntEndDate, @EndDate) > 31
         BEGIN
            RAISERROR ( N'خطا - عدم دسترسی به ردیف 285 سطوح امینتی', -- Message text.
                        16, -- Severity.
                        1 -- State.
                      );
            RETURN;
         END;         
      END;
      
      IF NOT EXISTS(SELECT * FROM Member_Ship WHERE RQRO_RQST_RQID = @Rqid AND RQRO_RWNO = @RqroRwno AND FIGH_FILE_NO = @FileNo AND RECT_CODE = '002')
         EXEC INS_MBSP_P @Rqid, @RqroRwno, @FileNo, '002', '001', @StrtDate, @EndDate, @PrntCont, @NumbMontOfer, @NumbOfAttnMont, 0, @AttnDayType;
      ELSE
         EXEC UPD_MBSP_P @Rqid, @RqroRwno, @FileNo, '002', '001', @StrtDate, @EndDate, @PrntCont, @NumbMontOfer, @NumbOfAttnMont, 0, @AttnDayType;
      
      UPDATE dbo.Member_Ship
         SET SUM_ATTN_MONT_DNRM = @SumNumbAttnMont
            ,FGPB_RWNO_DNRM = CASE WHEN FGPB_RWNO_DNRM IS NULL THEN (SELECT FGPB_RWNO_DNRM FROM dbo.Member_Ship WHERE RQRO_RQST_RQID = @Rqid AND RECT_CODE = '004') ELSE Member_Ship.FGPB_RWNO_DNRM END
            ,FGPB_RECT_CODE_DNRM = '004'
            ,RESN_APBS_CODE = @ResnApbsCode
            ,RESN_DESC = @ResnDesc
       WHERE RQRO_RQST_RQID = @Rqid
         AND RECT_CODE = '002';
         
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
