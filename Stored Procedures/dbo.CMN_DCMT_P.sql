SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[CMN_DCMT_P]
	@X XML
AS
BEGIN
   -- بررسی دسترسی کاربر
	DECLARE @AP BIT
	       ,@AccessString VARCHAR(250);
	SET @AccessString = N'<AP><UserName>' + SUSER_NAME() + '</UserName><Privilege>114</Privilege><Sub_Sys>5</Sub_Sys></AP>';	
   EXEC iProject.dbo.SP_EXECUTESQL N'SELECT @ap = DataGuard.AccessPrivilege(@P1)',N'@P1 ntext, @ap BIT OUTPUT',@AccessString , @ap = @ap output
   IF @AP = 0 
   BEGIN
      RAISERROR ( N'خطا - عدم دسترسی به ردیف 114 سطوح امینتی : شما مجوز درج و ویرایش اطلاعات و تصویر مدرک را ندارید', -- Message text.
               16, -- Severity.
               1 -- State.
               );
      RETURN;
   END
   -- پایان دسترسی
   
	DECLARE @Rqid BIGINT
	       ,@RqroRwno SMALLINT
	       ,@RqtpCode VARCHAR(3)
	       ,@RqttCode VARCHAR(3);
	
	SELECT @Rqid = @X.query('//Request').value('(Request/@rqid)[1]', 'BIGINT')
	      ,@RqtpCode = @X.query('//Request').value('(Request/@rqtpcode)[1]', 'VARCHAR(3)')
	      ,@RqttCode = @X.query('//Request').value('(Request/@rqttcode)[1]', 'VARCHAR(3)');
   
   DECLARE C$RQRVCMNDCMT CURSOR FOR
      SELECT r.query('.').value('(Request_Row/@rwno)[1]', 'SMALLINT')
        FROM @X.nodes('//Request_Row') Rqrv(r);
   
   DECLARE C$RDID CURSOR FOR
      SELECT Rd.Rdid
        FROM Request_Document Rd, Request_Requester Rq, Regulation Rg
       WHERE Rd.Rqrq_Code = Rq.Code
         AND Rq.Rqtp_Code = @RqtpCode
         AND Rq.Rqtt_Code = @RqttCode
         AND Rq.Regl_Year = Rg.Year
         AND Rq.Regl_Code = Rg.Code
         AND Rg.Type      = '001' -- هزینه
         AND Rg.Regl_Stat = '002';
   
   DECLARE @Rdid BIGINT;
   
   OPEN C$RQRVCMNDCMT;
   NEXTC$RQRVCMNDCMT:
   FETCH NEXT FROM C$RQRVCMNDCMT INTO @RqroRwno;
   
   IF @@FETCH_STATUS <> 0
      GOTO ENDC$RQRVCMNDCMT;
   
   OPEN C$RDID;
   NEXTC$RDID:
   FETCH NEXT FROM C$RDID INTO @Rdid;
   
   IF @@FETCH_STATUS <> 0
      GOTO ENDC$RDID;
   
   IF NOT EXISTS(SELECT * FROM Receive_Document T WHERE T.Rqro_Rqst_Rqid = @Rqid AND T.Rqro_Rwno = @RqroRwno AND T.Rqdc_Rdid = @Rdid)
      INSERT INTO Receive_Document(Rqro_Rqst_Rqid, Rqro_Rwno, Rqdc_Rdid, RCDC_STAT, PERM_STAT, DELV_DATE, STRT_DATE, END_DATE)
      VALUES                      (@Rqid         ,@RqroRwno , @Rdid    , '001'    , '001'    , GETDATE(), GETDATE(), DATEADD(MONTH, 1, GETDATE()));   
      
   GOTO NEXTC$RDID;
   ENDC$RDID:
   CLOSE C$RDID;
   DEALLOCATE C$RDID;
   
   GOTO NEXTC$RQRVCMNDCMT;
   ENDC$RQRVCMNDCMT:
   CLOSE C$RQRVCMNDCMT;
   DEALLOCATE C$RQRVCMNDCMT;
END
GO
