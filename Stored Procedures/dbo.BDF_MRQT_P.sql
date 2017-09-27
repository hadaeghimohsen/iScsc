SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[BDF_MRQT_P]
	@X XML
AS
BEGIN
	DECLARE @AP BIT
          ,@AccessString VARCHAR(250);
   SET @AccessString = N'<AP><UserName>' + SUSER_NAME() + '</UserName><Privilege>167</Privilege><Sub_Sys>5</Sub_Sys></AP>';	
   EXEC iProject.dbo.SP_EXECUTESQL N'SELECT @ap = DataGuard.AccessPrivilege(@P1)',N'@P1 ntext, @ap BIT OUTPUT',@AccessString , @ap = @ap output
   IF @AP = 0 
   BEGIN
      RAISERROR ( N'خطا - عدم دسترسی به ردیف 167 سطوح امینتی', -- Message text.
               16, -- Severity.
               1 -- State.
               );
      RETURN;
   END

	DECLARE @ErrorMessage NVARCHAR(MAX);
	BEGIN TRAN T1;
	BEGIN TRY
	   DECLARE @Rqid     BIGINT,
	           @RqtpCode VARCHAR(3),
	           @RqttCode VARCHAR(3),
	           @RegnCode VARCHAR(3),
	           @PrvnCode VARCHAR(3),
 	           @MdulName VARCHAR(11),
	           @SctnName VARCHAR(11);
      DECLARE @FileNo BIGINT;
         	
	   SELECT @Rqid     = @X.query('//Request').value('(Request/@rqid)[1]'    , 'BIGINT')
	         ,@RqtpCode = @X.query('//Request').value('(Request/@rqtpcode)[1]', 'VARCHAR(3)')
	         ,@RqttCode = @X.query('//Request').value('(Request/@rqttcode)[1]', 'VARCHAR(3)')
	         ,@MdulName = @X.query('//Request').value('(Request/@mdulname)[1]', 'VARCHAR(11)')
	         ,@SctnName = @X.query('//Request').value('(Request/@sctnname)[1]', 'VARCHAR(11)')
	         ,@FileNo   = @X.query('//Request_Row').value('(Request_Row/@fileno)[1]', 'BIGINT');      
   
      SELECT @RegnCode = REGN_CODE
            ,@PrvnCode = REGN_PRVN_CODE
        FROM Fighter
       WHERE FILE_NO = @FileNo;
      
      -- ثبت شماره درخواست 
      IF @Rqid IS NULL OR @Rqid = 0
      BEGIN
         EXEC dbo.INS_RQST_P
            @PrvnCode,
            @RegnCode,
            NULL,
            @RqtpCode,
            @RqttCode,
            NULL,
            NULL,
            NULL,
            @Rqid OUT;      
            
         UPDATE Request
            SET MDUL_NAME = @MdulName
              ,SECT_NAME = @SctnName
          WHERE RQID = @Rqid;                

      END
      ELSE
      BEGIN
         UPDATE dbo.Request
            SET SSTT_MSTT_CODE = 1
               ,SSTT_CODE = 1
          WHERE RQID = @Rqid;
          
         EXEC UPD_RQST_P
            @Rqid,
            @PrvnCode,
            @RegnCode,
            @RqtpCode,
            @RqttCode,
            NULL,
            NULL,
            NULL;            
      END

      -- ثبت ردیف درخواست 
      DECLARE @RqroRwno SMALLINT;
      SELECT @RqroRwno = Rwno
         FROM Request_Row
         WHERE RQST_RQID = @Rqid
           AND FIGH_FILE_NO = @FileNo;
           
      IF @RqroRwno IS NULL
      BEGIN
         EXEC INS_RQRO_P
            @Rqid
           ,@FileNo
           ,@RqroRwno OUT;
      END
      
      DECLARE @BdftRwno INT;
      
      IF NOT EXISTS(
         SELECT *
           FROM Body_Fitness
          WHERE RQRO_RQST_RQID = @Rqid
            AND RQRO_RWNO = @RqroRwno
            AND FIGH_FILE_NO = @FileNo
            AND RECT_CODE = '001'
      )
      BEGIN
         INSERT INTO Body_Fitness(RQRO_RQST_RQID, RQRO_RWNO, FIGH_FILE_NO, RECT_CODE, RWNO, BDFT_TYPE, MESR_TYPE, TOTL_EXRS_TIME, REST_TIME_BTWN_SET, NUMB_DAY_EXRS_PROG, PRE_MOVE_CHCK, BDFT_DESC)
         VALUES(@Rqid, @RqroRwno, @FileNo, '001', 0, '001', '001', '01:30:00', '00:01:00', 3, '002', ' ');
         
         SELECT @BdftRwno = RWNO
           FROM Body_Fitness
          WHERE RQRO_RQST_RQID = @Rqid
            AND RQRO_RWNO = @RqroRwno
            AND FIGH_FILE_NO = @FileNo
            AND RECT_CODE = '001';
         
         INSERT INTO Body_Fitness_Measurement (BDFT_FIGH_FILE_NO, BDFT_RECT_CODE, BDFT_RWNO, BODY_TYPE, RWNO, BDFM_DESC, MESR_VALU)
         SELECT @FileNo, '001', @BdftRwno, VALU, CAST(RAND(100) * 10 AS SMALLINT), ' ', 0
         FROM D$BODY;
      END;
      ELSE
      BEGIN
         DECLARE @BdftType VARCHAR(3)
                ,@MesrType VARCHAR(3)
                ,@TotlExrsTime TIME(0)
                ,@RestTimeBtwnSet TIME(0)
                ,@NumbDayExrsProg SMALLINT
                ,@PreMoveChck VARCHAR(3)
                ,@BdftDesc NVARCHAR(500);
        
        SELECT @BdftRwno = @X.query('//Body_Fitness').value('(Body_Fitness/@rwno)[1]'    , 'INT')
              ,@BdftType = @X.query('//Body_Fitness').value('(Body_Fitness/@bdfttype)[1]'    , 'VARCHAR(3)')
              ,@MesrType = @X.query('//Body_Fitness').value('(Body_Fitness/@mesrtype)[1]'    , 'VARCHAR(3)')
              ,@TotlExrsTime = @X.query('//Body_Fitness').value('(Body_Fitness/@totlexrstime)[1]'    , 'TIME(0)')
              ,@RestTimeBtwnSet = @X.query('//Body_Fitness').value('(Body_Fitness/@resttimebtwnset)[1]'    , 'TIME(0)')
              ,@NumbDayExrsProg = @X.query('//Body_Fitness').value('(Body_Fitness/@numbdayexrsprog)[1]'    , 'SMALLINT')
              ,@PreMoveChck = @X.query('//Body_Fitness').value('(Body_Fitness/@premovechck)[1]'    , 'VARCHAR(3)')
              ,@BdftDesc = @X.query('//Body_Fitness').value('(Body_Fitness/@bdftdesc)[1]'    , 'NVARCHAR(500)');
        
        UPDATE dbo.Body_Fitness
         SET BDFT_TYPE = @BdftType
            ,MESR_TYPE = @MesrType
            ,TOTL_EXRS_TIME = @TotlExrsTime
            ,REST_TIME_BTWN_SET = @RestTimeBtwnSet
            ,NUMB_DAY_EXRS_PROG = @NumbDayExrsProg
            ,PRE_MOVE_CHCK = @PreMoveChck
            ,BDFT_DESC = @BdftDesc
        WHERE RQRO_RQST_RQID = @Rqid
          AND RQRO_RWNO = @RqroRwno
          AND FIGH_FILE_NO = @FileNo 
          AND RECT_CODE = '001';
        
        DECLARE C$Bdms CURSOR FOR
         SELECT r.query('.').value('(Body_Fitness_Measurement/@bodytype)[1]', 'VARCHAR(3)')
               ,r.query('.').value('(Body_Fitness_Measurement/@rwno)[1]', 'SMALLINT')
               ,r.query('.').value('(Body_Fitness_Measurement/@bdfmdesc)[1]', 'NVARCHAR(250)')
               ,r.query('.').value('(Body_Fitness_Measurement/@mesrvalu)[1]', 'real')
           FROM @X.nodes('//Body_Fitness_Measurement') T(r);
        
        DECLARE @BodyType VARCHAR(3)
               ,@BdmsRwno SMALLINT
               ,@BdfmDesc NVARCHAR(250)
               ,@MesrValu REAL;
        
        OPEN C$Bdms;
        L$FC$Bdms:
        FETCH NEXT FROM C$Bdms INTO @BodyType, @BdmsRwno, @BdfmDesc, @MesrValu;
        
        IF @@FETCH_STATUS <> 0
           GOTO L$CC$Bdms;
        
        UPDATE dbo.Body_Fitness_Measurement
           SET BDFM_DESC = @BdfmDesc
              ,MESR_VALU = @MesrValu
         WHERE BDFT_RWNO = @BdftRwno
           AND BDFT_FIGH_FILE_NO = @FileNo
           AND BDFT_RECT_CODE = '001'
           AND BODY_TYPE = @BodyType
           AND RWNO = @BdmsRwno;
         
        GOTO L$FC$Bdms;
        L$CC$Bdms:
        CLOSE C$Bdms;
        DEALLOCATE C$Bdms;
      END
      
      
      DECLARE C$Chbf CURSOR FOR
         SELECT r.query('.').value('(Change_Body_Fitness/@bodytype)[1]', 'VARCHAR(3)')
               ,r.query('.').value('(Change_Body_Fitness/@rwno)[1]', 'SMALLINT')
               ,r.query('.').value('(Change_Body_Fitness/@efcttype)[1]', 'VARCHAR(3)')
               ,r.query('.').value('(Change_Body_Fitness/@chbfdesc)[1]', 'NVARCHAR(250)')
               ,r.query('.').value('(Change_Body_Fitness/@prtynumb)[1]', 'smallint')
               ,r.query('.').value('(Change_Body_Fitness/@indcweghdumb)[1]', 'VARCHAR(3)')
               ,r.query('.').value('(Change_Body_Fitness/@indcamntweghtype)[1]', 'VARCHAR(3)')
               ,r.query('.').value('(Change_Body_Fitness/@indcamntwegh)[1]', 'real')
               ,r.query('.').value('(Change_Body_Fitness/@stat)[1]', 'VARCHAR(3)')
           FROM @X.nodes('//Change_Body_Fitness') T(r);
      
      DECLARE @ChbfRwno SMALLINT
             ,@EfctType VARCHAR(3)
             ,@ChbfDesc NVARCHAR(250)
             ,@PrtyNumb SMALLINT
             ,@IndcWeghDumb VARCHAR(3)
             ,@IndcAmntWeghType VARCHAR(3)
             ,@IndcAmntWegh REAL
             ,@Stat VARCHAR(3);
      
      OPEN C$Chbf;
      L$FC$Chbf:
      FETCH NEXT FROM C$Chbf INTO @BodyType, @ChbfRwno, @EfctType, @ChbfDesc, @PrtyNumb, @indcweghdumb, @indcamntweghtype, @indcamntwegh, @stat;
      
      IF @@FETCH_STATUS <> 0
         GOTO L$CC$Chbf;
      
      IF NOT EXISTS(
         SELECT * 
           FROM dbo.Change_Body_Fitness
          WHERE BDFT_FIGH_FILE_NO = @FileNo
            AND BDFT_RECT_CODE = '001'
            AND BDFT_RWNO = @BdftRwno
            AND BODY_TYPE = @BodyType
            AND ISNULL(@ChbfRwno, 0) = 0
      )
      BEGIN
         MERGE dbo.Change_Body_Fitness T
         USING (SELECT @ChbfRwno AS ChbfRwno, @BodyType AS BodyType) S
         ON (T.BDFT_FIGH_FILE_NO = @FileNo AND
             T.BDFT_RECT_CODE = '001' AND
             T.BDFT_RWNO = @BdftRwno AND
             T.BODY_TYPE = S.BodyType AND 
             T.RWNO = S.ChbfRwno)
         WHEN MATCHED THEN
            UPDATE
               SET EFCT_TYPE = @EfctType
                  ,CHBF_DESC = @ChbfDesc
                  ,PRTY_NUMB = @PrtyNumb
                  ,INDC_WEGH_DUMB = @IndcWeghDumb
                  ,INDC_AMNT_WEGH_TYPE = @IndcAmntWeghType
                  ,INDC_AMNT_WEGH = @IndcAmntWegh
                  ,STAT = @Stat
         WHEN NOT MATCHED THEN
            INSERT (BDFT_FIGH_FILE_NO, BDFT_RECT_CODE, BDFT_RWNO, BODY_TYPE, RWNO, EFCT_TYPE, CHBF_DESC, PRTY_NUMB, INDC_WEGH_DUMB, INDC_AMNT_WEGH_TYPE, INDC_AMNT_WEGH, STAT)
            VALUES (@FileNo,           '001',          @BdftRwno, @BodyType, 0,    @EfctType, @ChbfDesc, @PrtyNumb, @IndcWeghDumb,  @IndcAmntWeghType,   @IndcAmntWegh,  @Stat);
      END
      
      -- Body_Fitness_Movement
      DECLARE C$Bfmm CURSOR FOR
         SELECT r.query('.').value('(Body_Fitness_Movement/@bodytype)[1]', 'VARCHAR(3)')
               ,r.query('.').value('(Body_Fitness_Movement/@rwno)[1]', 'SMALLINT')
               ,r.query('.').value('(Body_Fitness_Movement/@weekdaytype)[1]', 'VARCHAR(3)')
               ,r.query('.').value('(Body_Fitness_Movement/@bbfmbfid)[1]', 'BIGINT')
               ,r.query('.').value('(Body_Fitness_Movement/@resttimeinset)[1]', 'TIME(0)')
               ,r.query('.').value('(Body_Fitness_Movement/@timeperset)[1]', 'TIME(0)')
               ,r.query('.').value('(Body_Fitness_Movement/@numbofmoveinset)[1]', 'smallint')
               ,r.query('.').value('(Body_Fitness_Movement/@amntwegh)[1]', 'REAL')
               ,r.query('.').value('(Body_Fitness_Movement/@ordr)[1]', 'SMALLINT')
               ,r.query('.').value('(Body_Fitness_Movement/@premove)[1]', 'VARCHAR(3)')
           FROM @X.nodes('//Body_Fitness_Movement') T(r);
      
      DECLARE @TBodyType VARCHAR(3)
             ,@BfmmRwno SMALLINT
             ,@WeekDayType VARCHAR(3)
             ,@BbfmBfid BIGINT
             ,@RestTimeInSet TIME(0)
             ,@TimePerSet TIME(0)
             ,@NumbOfMoveInSet SMALLINT
             ,@AmntWegh REAL
             ,@Ordr SMALLINT
             ,@PreMove VARCHAR(3);      
      
      OPEN C$Bfmm;
      L$FC$Bfmm:
      FETCH NEXT FROM C$Bfmm INTO @TBodyType, @BfmmRwno ,@WeekDayType, @BbfmBfid, @RestTimeInSet, @TimePerSet, @NumbOfMoveInSet, @AmntWegh, @Ordr, @PreMove;
      
      IF @@FETCH_STATUS <> 0
         GOTO L$CC$Bfmm;

      IF @BodyType != @TBodyType
         GOTO L$FC$Bfmm;
      
      MERGE dbo.Body_Fitness_Movement T
      USING (SELECT @BfmmRwno AS BfmmRwno) S -- @WeekDayType , @BbfmBfid, @RestTimeInSet, @TimePerSet, @NumbOfMoveInSet, @AmntWegh, @Ordr, @PreMove) S
      ON (T.CHBF_BDFT_FIGH_FILE_NO = @FileNo AND
          T.CHBF_BDFT_RECT_CODE = '001' AND
          T.CHBF_BDFT_RWNO = @BdftRwno AND
          T.CHBF_BODY_TYPE = @BodyType AND
          T.CHBF_RWNO = @ChbfRwno AND
          T.RWNO = @BfmmRwno)
      WHEN NOT MATCHED THEN
         INSERT (CHBF_BDFT_FIGH_FILE_NO, CHBF_BDFT_RECT_CODE, CHBF_BDFT_RWNO, CHBF_BODY_TYPE, CHBF_RWNO, RWNO, BBFM_BFID, WEEK_DAY_TYPE, REST_TIME_IN_SET, TIME_PER_SET, NUMB_OF_MOVE_IN_SET, AMNT_WEGH, ORDR, PRE_MOVE)
         VALUES (@FileNo,               '001',                @BdftRwno     , @BodyType     , @ChbfRwno, 0,   @BbfmBfid,  @WeekDayType,  @RestTimeInSet,   @TimePerSet,  @NumbOfMoveInSet,    @AmntWegh, @Ordr, @PreMove)
      WHEN MATCHED THEN
         UPDATE 
            SET WEEK_DAY_TYPE = @WeekDayType
               ,REST_TIME_IN_SET = @RestTimeInSet
               ,TIME_PER_SET = @TimePerSet
               ,NUMB_OF_MOVE_IN_SET = @NumbOfMoveInSet
               ,AMNT_WEGH = @AmntWegh
               ,ORDR = @Ordr
               ,PRE_MOVE = @PreMove;
      
      GOTO L$FC$Bfmm;
      L$CC$Bfmm:
      CLOSE C$Bfmm;
      DEALLOCATE C$Bfmm;
      -- Body_Fitness_Movement
      
      
      GOTO L$FC$Chbf;
      L$CC$Chbf:
      CLOSE C$Chbf;
      DEALLOCATE C$Chbf;
      
      BEGIN                
         -- اگر در ثبت موقت باشیم و برای نوع درخواست و متقاضی آیین نامه هزینه داری داشته باشیم درخواست را به فرم اعلام هزینه ارسال میکنیم            
         IF EXISTS(
            SELECT *
              FROM Request_Row Rr
             WHERE Rr.FIGH_FILE_NO = @FileNo
               AND Rr.RQST_RQID = @Rqid
               AND EXISTS(
                  SELECT *
                    FROM dbo.VF$All_Expense_Detail(
                     @PrvnCode, 
                     @RegnCode, 
                     NULL, 
                     @RqtpCode, 
                     @RqttCode, 
                     NULL, 
                     NULL, 
                     --F.Mtod_Code_Dnrm , 
                     --F.Ctgy_Code_Dnrm)
                     NULL,
                     NULL)
               )
         )
         BEGIN
            IF NOT EXISTS(SELECT * FROM Request WHERE RQID = @Rqid AND SSTT_MSTT_CODE = 2 AND SSTT_CODE = 2)
            BEGIN
               SELECT @X = (
                  SELECT @Rqid '@rqid'          
                        ,@RqtpCode '@rqtpcode'
                        ,@RqttCode '@rqttcode'
                        ,@RegnCode '@regncode'  
                        ,@PrvnCode '@prvncode'
                  FOR XML PATH('Request'), ROOT('Process')
               );
               EXEC INS_SEXP_P @X;             

               UPDATE Request
                  SET SEND_EXPN = '002'
                     ,SSTT_MSTT_CODE = 2
                     ,SSTT_CODE = 2
                WHERE RQID = @Rqid;
           END
            ELSE
            -- به درخواست آقای فهیم در تاریخ 1395/04/10 که مقرر گردید سیستم بتواند
            -- ثبت چند ماهی هم داشته باشد که بتوان هنرجویان را ترغیب به پرداخت هزینه
            -- شهریه باشگاه برای چندماه متوالی کرد
            BEGIN
                -- این شرط همیشه نادرست می باشد بخاطر اینکه در بالا اطلاعات سبک و رشته جدید بروز رسانی با مقدار جدید انجام میشود
                /*IF EXISTS (
                   SELECT *
                     FROM dbo.Fighter_Public Fp
                    WHERE Fp.RQRO_RQST_RQID = @Rqid
                      AND Fp.FIGH_FILE_NO = @FileNo
                      AND (
                          Fp.MTOD_CODE <> @MtodCode
                       OR Fp.CTGY_CODE <> @CtgyCode
                      )                     
                )*/
                BEGIN
                 UPDATE Request
                    SET SEND_EXPN = '001'
                       ,SSTT_MSTT_CODE = 1
                       ,SSTT_CODE = 1
                  WHERE RQID = @Rqid;                

                 --Raiserror('Raiseerror', 16, 1)
                 
                 /*DELETE Payment_Detail 
                  WHERE PYMT_RQST_RQID = @Rqid;          
                 DELETE Payment
                  WHERE RQST_RQID = @Rqid; */  
                 
                 SELECT @X = (
                    SELECT @Rqid '@rqid'          
                          ,@RqtpCode '@rqtpcode'
                          ,@RqttCode '@rqttcode'
                          ,@RegnCode '@regncode'  
                          ,@PrvnCode '@prvncode'
                    FOR XML PATH('Request'), ROOT('Process')
                 );
                 EXEC INS_SEXP_P @X;             

                 UPDATE Request
                    SET SEND_EXPN = '002'
                       ,SSTT_MSTT_CODE = 2
                       ,SSTT_CODE = 2
                  WHERE RQID = @Rqid;            
                END
                --ELSE
                BEGIN
                   DECLARE @Qnty SMALLINT;
                   
                   SELECT @Qnty = NUMB_OF_MONT_DNRM - ISNULL(NUMB_MONT_OFER, 0)
                     FROM dbo.Member_Ship
                    WHERE RQRO_RQST_RQID = @Rqid
                      AND RQRO_RWNO = @RqroRwno;
                   
                   --Raiserror(@Qnty, 16, 1)
                   PRINT @Qnty;
                   IF @Qnty <= 0
                   BEGIN
                      RAISERROR(N'تعداد ماه های تخفیف بیشتر از حد مجاز می باشد، لطفا اصلاح و دوباره امتحان کنید.', 16, 1);
                   END
                   
                   UPDATE dbo.Payment_Detail
                      SET QNTY = @Qnty
                    WHERE PYMT_RQST_RQID = @Rqid
                      AND RQRO_RWNO = @RqroRwno
                      AND ISNULL(ADD_QUTS, '001') = '001';                   
                END;
           END
         END
         ELSE
         BEGIN
            UPDATE Request
               SET SEND_EXPN = '001'
                  ,SSTT_MSTT_CODE = 1
                  ,SSTT_CODE = 1
             WHERE RQID = @Rqid;                
            
            --Raiserror('Raiseerror', 16, 1)
            
            DELETE Payment_Detail 
             WHERE PYMT_RQST_RQID = @Rqid;          
            DELETE Payment
             WHERE RQST_RQID = @Rqid;            
         END  
      END 
      
   COMMIT TRAN T1;
   END TRY
   BEGIN CATCH
      SET @ErrorMessage = ERROR_MESSAGE();
      RAISERROR ( @ErrorMessage, -- Message text.
               16, -- Severity.
               1 -- State.
               );
      ROLLBACK TRAN T1;
   END CATCH
END;

GO
