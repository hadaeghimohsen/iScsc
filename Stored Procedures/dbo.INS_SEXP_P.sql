SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[INS_SEXP_P]
	@X XML
AS
BEGIN
	DECLARE @Rqid BIGINT
	       ,@RqroRwno SMALLINT
	       ,@RqtpCode VARCHAR(3)
	       ,@RqttCode VARCHAR(3)
	       ,@PrvnCode VARCHAR(3)
	       ,@RegnCode VARCHAR(3)
	       ,@MtodCode BIGINT
	       ,@CtgyCode BIGINT
	       ,@Qnty SMALLINT;
   
   SELECT @Rqid     = @X.query('//Request').value('(Request/@rqid)[1]'    , 'BIGINT')
         ,@RqtpCode = @X.query('//Request').value('(Request/@rqtpcode)[1]', 'VARCHAR(3)')
         ,@RqttCode = @X.query('//Request').value('(Request/@rqttcode)[1]', 'VARCHAR(3)')
         ,@PrvnCode = @X.query('//Request').value('(Request/@prvncode)[1]', 'VARCHAR(3)')
         ,@RegnCode = @X.query('//Request').value('(Request/@regncode)[1]', 'VARCHAR(3)')
         ,@Qnty = 1;
   
   IF EXISTS(
      SELECT *
        FROM Request R
       WHERE R.RQID = @Rqid
         AND R.SSTT_MSTT_CODE = 2
         AND R.SSTT_CODE = 2
         AND R.RQTP_CODE != '016'
   )
   BEGIN
      RAISERROR('درخواست در وضعیت صدور هزینه قرار گرفته دیگر نمی توانید اعلام هزینه مجدد کنید. اگر می خواهید درخواست را انصراف بزنید و دوباره از ثبت موقت شروع به ثبت اطلاعات کنید.' , 16, 1);
      RETURN;
   END
         
   IF LEN(@RqtpCode) = 0 OR
      LEN(@RqttCode) = 0 OR
      LEN(@PrvnCode) = 0 OR
      LEN(@RegnCode) = 0 OR
--          @MtodCode  = 0 OR
--          @CtgyCode  = 0 OR
          @Rqid      = 0
    BEGIN
      RAISERROR('با اطلاعات وارد شده نمی توان هزینه ثبت کرد' , 16, 1);
      RETURN;
    END
    
    -- 1395/08/09 * بخاطر ویرایش کردن آیتم درخواست بعد از پرداختی
    /*IF EXISTS(SELECT * FROM dbo.Payment_Method WHERE PYMT_RQST_RQID = @Rqid)
    BEGIN
      RAISERROR('کاربر گرامی بعد از اضافه کردن مبلغ پرداختی برای هزینه دیگر قادر به ویرایش کردن نیستید مگر اینکه مبلغ پرداختی را حذف کنید' , 16, 1);
      RETURN;
    END*/
    
    -- 1401/09/17 * MahsaAmini
    DELETE dbo.Payment_Discount
     WHERE PYMT_RQST_RQID = @Rqid
       AND PYDT_CODE_DNRM IN (
           SELECT pd.CODE
             FROM dbo.Payment_Detail pd
            WHERE pd.PYMT_RQST_RQID = @Rqid
              AND pd.ADD_QUTS = '001'
       );
    
    DELETE Payment_Detail 
     WHERE PYMT_RQST_RQID = @Rqid
       AND ADD_QUTS = '001';
    
    
    DELETE Payment
     WHERE RQST_RQID = @Rqid
       AND (
		   NOT eXISTS (
			  SELECT * 
				FROM Payment_Detail
			   WHERE PYMT_RQST_RQID = @Rqid
		   )
		   AND
		   NOT EXISTS (
			  SELECT * 
			    FROM Payment_Discount
			   WHERE PYMT_RQST_RQID = @Rqid
		   )
		   AND
		   NOT EXISTS (
			  SELECT * 
			    FROM dbo.Payment_Method
			   WHERE PYMT_RQST_RQID = @Rqid
		   )
	   );
    
    DECLARE C$RQRV CURSOR FOR
      SELECT RWNO
        FROM Request_Row
       WHERE Rqst_Rqid = @Rqid
      ORDER BY RWNO;      
    
    -- 1396/05/04 ************ این قسمت باید برای کلاس های چند جلسه ای باید اصلاح شود
    -- در این قسمت باید بگویم که اگر گزینه جلسه ترکیبی می باشد مشخص شود که چه کلاس هایی انتخاب شده که هزینه ها را جدا جدا انتخاب کنیم ولی اگر کلاس عادی باشد همین گزینه کفایت میکند
    
    IF @RqttCode = '008'
    BEGIN
       IF NOT EXISTS(SELECT * FROM Payment WHERE RQST_RQID = @Rqid)
       BEGIN
		   INSERT INTO Payment (RQST_RQID, CASH_CODE, TYPE) 
		   /*SELECT DISTINCT @Rqid, Cash_Code, '002'
		   FROM VF$All_Expense_Detail(@PrvnCode, @RegnCode, NULL, @RqtpCode, @RqttCode, NULL, NULL, @MtodCode, @CtgyCode) a, dbo.Session b, dbo.Member_Ship c
		   WHERE a.ADD_QUTS = '001'
		     AND a.EXPN_CODE = b.EXPN_CODE
		     AND b.MBSP_FIGH_FILE_NO = c.FIGH_FILE_NO
		     AND b.MBSP_RECT_CODE = c.RECT_CODE
		     AND b.MBSP_RWNO = c.RWNO
		     AND c.RQRO_RQST_RQID = @Rqid;*/
		   SELECT DISTINCT @Rqid, c.CODE, '002'
		     FROM dbo.Cash c
		    WHERE c.CASH_STAT = '002'
	    END
    END
    ELSE 
    BEGIN
       IF NOT EXISTS(SELECT * FROM Payment WHERE RQST_RQID = @Rqid)
       BEGIN
		   INSERT INTO Payment (RQST_RQID, CASH_CODE, TYPE) 
		   /*SELECT DISTINCT @Rqid, Cash_Code, '002'
		   FROM VF$All_Expense_Detail(@PrvnCode, @RegnCode, NULL, @RqtpCode, @RqttCode, NULL, NULL, @MtodCode, @CtgyCode)
		   WHERE ADD_QUTS = '001';*/
		   SELECT DISTINCT @Rqid, c.CODE, '002'
		     FROM dbo.Cash c
		    WHERE c.CASH_STAT = '002'
	    END
	END
    
    OPEN C$RQRV;
    FetchNextRequestRow:
    FETCH NEXT FROM C$RQRV INTO @RqroRwno;
    
    IF @RqtpCode IN ( '001' , '022', '023' )
    BEGIN  
       SELECT @MtodCode = p.MTOD_CODE, @CtgyCode = p.CTGY_CODE
         FROM Fighter_Public P
        WHERE P.RQRO_RQST_RQID = @Rqid;
       
       SELECT @Qnty = 1--NUMB_OF_MONT_DNRM - ISNULL(NUMB_MONT_OFER, 0)
         FROM dbo.Member_Ship
        WHERE RQRO_RQST_RQID = @Rqid
          AND RQRO_RWNO = @RqroRwno;
       
       --PRINT @Qnty;
       
       IF @Qnty <= 0
       BEGIN
          SET @Qnty = 1;
          --RAISERROR(N'تعداد ماه های تخفیف بیشتر از حد مجاز می باشد، لطفا اصلاح و دوباره امتحان کنید.', 16, 1);
       END
    END    
    ELSE IF @RqtpCode = '006'
       SELECT @MtodCode = Ctgy_Mtod_Code, @CtgyCode = Ctgy_Code
         FROM Test
        WHERE RQRO_RQST_RQID = @Rqid 
          AND RQRO_RWNO      = @RqroRwno;
    ELSE IF @RqtpCode IN ( '002', '003', '004', '005', '007', '008', '009', '010', '011', '012', '021' )
      SELECT @MtodCode = F.MTOD_CODE_DNRM, @CtgyCode = F.CTGY_CODE_DNRM      
        FROM Request R, Request_Row Rr, Fighter F
       WHERE R.RQID = @Rqid
         AND R.RQID = Rr.RQST_RQID
         AND Rr.FIGH_FILE_NO = F.FILE_NO
         AND Rr.RWNO = @RqroRwno
         AND R.RQTP_CODE = @RqtpCode;
    
    IF @RqtpCode = '009'
      SELECT @Qnty = 1--NUMB_OF_MONT_DNRM - ISNULL(NUMB_MONT_OFER, 0)
         FROM dbo.Member_Ship
        WHERE RQRO_RQST_RQID = @Rqid
          AND RQRO_RWNO = @RqroRwno;
     
     IF @Qnty <= 0
       BEGIN
          SET @Qnty = 1;
          --RAISERROR(N'تعداد ماه های تخفیف بیشتر از حد مجاز می باشد، لطفا اصلاح و دوباره امتحان کنید.', 16, 1);
       END    
       
    IF @@FETCH_STATUS <> 0
      GOTO EndFetchRequestRow;
    
    
    IF @RqtpCode NOT IN ('016')
    BEGIN 
       IF @RqtpCode IN ( '001', '009' ) AND 
          @RqttCode = '008' AND 
          ( 
            EXISTS(SELECT * FROM dbo.Fighter_Public WHERE RQRO_RQST_RQID = @Rqid AND [TYPE] = '009') OR 
            EXISTS(SELECT * FROM dbo.Fighter WHERE RQST_RQID = @Rqid AND FGPB_TYPE_DNRM = '009' ) 
          )
       BEGIN
          INSERT INTO Payment_Detail (PYMT_RQST_RQID, PYMT_CASH_CODE, RQRO_RWNO, EXPN_CODE, Code, QNTY)
          SELECT @Rqid, T.Cash_Code, @RqroRwno, T.Expn_Code, dbo.GNRT_NVID_U(), T.TOTL_SESN
            FROM
          (SELECT E.CASH_CODE, S.EXPN_CODE, /* 1306/02/06 SUM(S.TOTL_SESN)*/1 AS TOTL_SESN
             FROM Member_Ship m, [Session] s, VF$All_Expense_Detail(@PrvnCode, @RegnCode, NULL, @RqtpCode, @RqttCode, NULL, NULL, NULL, NULL) E
            WHERE m.RQRO_RQST_RQID = @Rqid 
              AND m.FIGH_FILE_NO = s.MBSP_FIGH_FILE_NO 
              AND m.RECT_CODE = s.MBSP_RECT_CODE 
              AND m.RWNO = s.MBSP_RWNO
              AND E.EXPN_CODE = S.EXPN_CODE
              AND S.TOTL_SESN > 0
            GROUP BY E.CASH_CODE, S.EXPN_CODE) T;
       END
       ELSE
          INSERT INTO Payment_Detail (PYMT_RQST_RQID, PYMT_CASH_CODE, RQRO_RWNO, EXPN_CODE, Code, QNTY, PYDT_DESC)
          SELECT @Rqid, Cash_Code, @RqroRwno, Expn_Code, dbo.GNRT_NVID_U(), @Qnty, EXPN_DESC
          FROM VF$All_Expense_Detail(@PrvnCode, @RegnCode, NULL, @RqtpCode, @RqttCode, NULL, NULL, @MtodCode, @CtgyCode)
          WHERE ADD_QUTS = '001';          
    END
    --ELSE IF @RqtpCode = '016' AND @RqttCode = '008' AND EXISTS(SELECT * FROM dbo.Fighter WHERE RQST_RQID = @Rqid AND FGPB_TYPE_DNRM = '009')
    --BEGIN
    --   INSERT INTO Payment_Detail (PYMT_RQST_RQID, PYMT_CASH_CODE, RQRO_RWNO, EXPN_CODE, Code, QNTY)
    --   SELECT @Rqid, T.Cash_Code, @RqroRwno, T.Expn_Code, dbo.GNRT_NVID_U(), T.TOTL_SESN
    --     FROM
    --   (SELECT E.CASH_CODE, S.EXPN_CODE, SUM(S.TOTL_SESN) AS TOTL_SESN
    --      FROM Member_Ship m, [Session] s, VF$All_Expense_Detail(@PrvnCode, @RegnCode, NULL, @RqtpCode, @RqttCode, NULL, NULL, NULL, NULL) E
    --     WHERE m.RQRO_RQST_RQID = @Rqid 
    --       AND m.FIGH_FILE_NO = s.MBSP_FIGH_FILE_NO 
    --       AND m.RECT_CODE = s.MBSP_RECT_CODE 
    --       AND m.RWNO = s.MBSP_RWNO
    --       AND E.EXPN_CODE = S.EXPN_CODE
    --     GROUP BY E.CASH_CODE, S.EXPN_CODE) T;
    --END
    
    GOTO FetchNextRequestRow;
    EndFetchRequestRow:
    CLOSE C$RQRV;
    DEALLOCATE C$RQRV;
    
    
    /*SET @X = '<Process><Request rqid="" msttcode="" ssttcode=""/></Process>';
    SET @X.modify(
      'replace value of (//Request/@rqid)[1]
       with sql:variable("@Rqid")'
    );
    
    SET @X.modify(
      'replace value of (//Request/@msttcode)[1]
       with 2'
    );
    
    SET @X.modify(
      'replace value of (//Request/@ssttcode)[1]
       with 1'
    );
    EXEC dbo.NEXT_LEVL_F @X;*/
    
END
GO
