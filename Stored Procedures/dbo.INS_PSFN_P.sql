SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[INS_PSFN_P]
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
   INSERT INTO Physical_Fitness(RQRO_RQST_RQID, RQRO_RWNO, FIGH_FILE_NO, RECT_CODE, PULL_UP, PUSH_UP, SQUT_TRST, SQUT_JUMP, SIT_UP)
   VALUES (@Rqid, @RqroRwno, @FileNo, @RectCode, @PullUp, @PushUp, @SqutTrst, @SqutJump, @SitUp);
END
GO
