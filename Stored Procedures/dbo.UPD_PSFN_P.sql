SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[UPD_PSFN_P]
	@Rqid BIGINT
  ,@RqroRwno SMALLINT
  ,@FileNo BIGINT
  ,@RectCode VARCHAR(3)
  ,@PullUp REAL
  ,@PushUp REAL
  ,@SqutTrst REAL
  ,@SqutJump REAL
  ,@SitUp REAL  
AS
BEGIN
   UPDATE Physical_Fitness
      SET PULL_UP = @PullUp
         ,PUSH_UP = @PushUp
         ,SQUT_TRST = @SqutTrst
         ,SQUT_JUMP = @SqutJump
         ,SIT_UP = @SitUp
    WHERE RQRO_RQST_RQID = @Rqid
      AND RQRO_RWNO = @RqroRwno
      AND FIGH_FILE_NO = @FileNo
      AND RECT_CODE = @RectCode;
END
GO
