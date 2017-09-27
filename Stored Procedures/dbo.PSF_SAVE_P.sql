SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[PSF_SAVE_P]
	-- Add the parameters for the stored procedure here
	@X XML
	/* Sample Xml
   <Process>
      <Request rqid=""/>
   </Process>
*/
AS
BEGIN
	/*
	   شرایط ارسال داده ها مربوط به جدول درخواست
	   1 - درخواست جدید می باشد و ستون شماره درخواست خالی می باشد
	   2 - درخواست قبلا ثبت شده و ستون شماره درخواست خالی نمی باشد
	*/
   DECLARE @AP BIT
          ,@AccessString VARCHAR(250);
   SET @AccessString = N'<AP><UserName>' + SUSER_NAME() + '</UserName><Privilege>85</Privilege><Sub_Sys>5</Sub_Sys></AP>';	
   EXEC iProject.dbo.SP_EXECUTESQL N'SELECT @ap = DataGuard.AccessPrivilege(@P1)',N'@P1 ntext, @ap BIT OUTPUT',@AccessString , @ap = @ap output
   IF @AP = 0 
   BEGIN
      RAISERROR ( N'خطا - عدم دسترسی به ردیف 85 سطوح امینتی', -- Message text.
               16, -- Severity.
               1 -- State.
               );
      RETURN;
   END
	
	DECLARE @ErrorMessage NVARCHAR(MAX);
	BEGIN TRAN T1;
	BEGIN TRY
	   DECLARE @Rqid     BIGINT
	          ,@PrvnCode VARCHAR(3)
	          ,@RegnCode VARCHAR(3);
   	
	   SELECT @Rqid     = @X.query('//Request').value('(Request/@rqid)[1]'        , 'BIGINT')
	         ,@PrvnCode = @X.query('//Request').value('(Request/@prvncode)[1]'    , 'VARCHAR(3)')
	         ,@RegnCode = @X.query('//Request').value('(Request/@regncode)[1]'    , 'VARCHAR(3)');
      
      DECLARE @FileNo   BIGINT
             ,@RqroRwno SMALLINT
             ,@PullUp REAL
             ,@PushUp REAL
             ,@SqutTrst REAL
             ,@SqutJump REAL
             ,@SitUp REAL;
             
      DECLARE C$RQRV CURSOR FOR
         SELECT Rwno, Figh_File_No
           FROM Request_Row Rr, @X.nodes('//Request_Row')R(Rt)
          WHERE Rr.Rqst_Rqid = @Rqid            
            AND Rr.Recd_Stat = '002';
            --AND Rr.Figh_File_No = Rt.query('Fighter').value('(Fighter/@fileno)[1]', 'BIGINT');
      
      OPEN C$RQRV;
      NextFromRqrv:
      FETCH NEXT FROM C$RQRV INTO @RqroRwno, @FileNo;
                     
      IF @@FETCH_STATUS <> 0   
         GOTO EndFetchRqrv;

      SELECT @PullUp = r.query('Physical_Fitness').value('(Physical_Fitness/@pullup)[1]', 'REAL')
            ,@PushUp = r.query('Physical_Fitness').value('(Physical_Fitness/@pushup)[1]', 'REAL')
            ,@SqutTrst = r.query('Physical_Fitness').value('(Physical_Fitness/@squttrst)[1]', 'REAL')
            ,@SqutJump = r.query('Physical_Fitness').value('(Physical_Fitness/@squtjump)[1]', 'REAL')
            ,@SitUp = r.query('Physical_Fitness').value('(Physical_Fitness/@situp)[1]', 'REAL')
        FROM @X.nodes('//Request_Row') F(r)
       WHERE r.query('.').value('(Request_Row/@fileno)[1]', 'BIGINT') = @FileNo;
      
      IF NOT EXISTS(
      SELECT *
        FROM Physical_Fitness
       WHERE FIGH_FILE_NO = @FileNo
         AND RQRO_RQST_RQID = @Rqid
         AND RECT_CODE = '004'
      )
      BEGIN
         EXEC INS_PSFN_P 
            @Rqid
           ,@RqroRwno
           ,@FileNo
           ,'004'
           ,@PullUp
           ,@PushUp
           ,@SqutTrst
           ,@SqutJump
           ,@SitUp;
      END
      ELSE
      BEGIN
         EXEC UPD_PSFN_P 
            @Rqid
           ,@RqroRwno
           ,@FileNo
           ,'004'
           ,@PullUp
           ,@PushUp
           ,@SqutTrst
           ,@SqutJump
           ,@SitUp;
      END     

      EXEC UPD_PSFN_P 
         @Rqid
        ,@RqroRwno
        ,@FileNo
        ,'001'
        ,@PullUp
        ,@PushUp
        ,@SqutTrst
        ,@SqutJump
        ,@SitUp;           

      /*DECLARE @AttnDate DATE;
      SET @AttnDate = GETDATE();
      
      IF NOT EXISTS(
      SELECT * 
        FROM Attendance A
       WHERE A.FIGH_FILE_NO = @FileNo
         AND CAST(A.ATTN_DATE AS DATE) = CAST(@AttnDate AS DATE)
      )   
         EXEC INS_ATTN_P NULL, @FileNo, @AttnDate;
      */
      
      GOTO NextFromRqrv;
      EndFetchRqrv:
      CLOSE C$RQRV;
      DEALLOCATE C$RQRV;
      
      IF (SELECT COUNT(*)
           FROM Request_Row Rr
          WHERE Rr.RQST_RQID = @Rqid            
            AND Rr.RECD_STAT = '002') = 
          (SELECT COUNT(*)
           FROM Physical_Fitness T
          WHERE T.RQRO_RQST_RQID = @Rqid            
            AND T.RECT_CODE = '004'
            AND T.PULL_UP IS NOT NULL
            AND T.PUSH_UP IS NOT NULL
            AND T.SQUT_TRST IS NOT NULL
            AND T.SQUT_JUMP IS NOT NULL
            AND T.SIT_UP IS NOT NULL)            
      BEGIN
         SET @X = '<Process><Request rqid=""/></Process>';
         SET @X.modify(
            'replace value of (//Request/@rqid)[1]
             with sql:variable("@Rqid")'
         );         
         EXEC dbo.END_RQST_P @X;
      END
      
      COMMIT TRAN T1;
   END TRY
   BEGIN CATCH
	   IF (SELECT CURSOR_STATUS('local','C$RQRV')) >= -1
      BEGIN
        IF (SELECT CURSOR_STATUS('local','C$RQRV')) > -1
         BEGIN
          CLOSE C$Fighter
         END
       DEALLOCATE C$Fighter
      END
            
      SET @ErrorMessage = ERROR_MESSAGE();
      RAISERROR ( @ErrorMessage, -- Message text.
               16, -- Severity.
               1 -- State.
               );
      ROLLBACK TRAN;
   END CATCH;   
END
GO
