package weblab.client;

// JAVA 1.1 COMPLIANT

import java.math.BigDecimal;

/**
 * Represents VAR1, the primary sweep source.  VAR1Function consists
 * of a scale (one of LIN_SCALE, LOG10_SCALE, LOG25_SCALE, and
 * LOG50_SCALE), a start value, a stop value, and a step value (only
 * applicable in LIN_SCALE).
 *
 * VAR1Function is immutable.
 */
public class VAR1Function extends SourceFunction
{
  // sweep scales
  public static final int LIN_SCALE = 1;
  public static final int LOG10_SCALE = 2; 
  public static final int LOG25_SCALE = 3;
  public static final int LOG50_SCALE = 4;


  // number of decimal places to round BigDecimals to in order to get
  // rid of floating point math issues in the arithmetic that created
  // them (note that this rounding is applied before floor and ceiling
  // roundings, so we don't want this number to be too low)
  private static final int TOLERANCE_SCALE = 6;


  private int scale;
  private BigDecimal start;
  private BigDecimal stop;
  private BigDecimal step;

  /**
   * Creates a new VAR1Function with default values.
   */
  public VAR1Function()
  {
    this(LIN_SCALE, BigDecimal.valueOf(0), BigDecimal.valueOf(0),
	 new BigDecimal("0.1"));
  }

  /**
   * Creates a new VAR1Function with the specified values.  Note that
   * the step value is ignored when the scale is not LIN_SCALE.
   *
   * requires: scale is one of LIN_SCALE, LOG10_SCALE, LOG25_SCALE,
   * LOG50_SCALE.
   */
  public VAR1Function(int scale, BigDecimal start, BigDecimal stop,
		      BigDecimal step)
  {
    this.scale = scale;
    this.start = start;
    this.stop = stop;
    this.step = step;
  }

  public final int getType()
  {
    return VAR1_TYPE;
  }

  /**
   * Returns the scale of this (LIN_SCALE, LOG10_SCALE, LOG25_SCALE,
   * or LOG50_SCALE).
   */
  public final int getScale()
  {
    return this.scale;
  }

  /**
   * Returns the start value of this.
   */
  public final BigDecimal getStart()
  {
    return this.start;
  }

  /**
   * Returns the stop value of this.
   */
  public final BigDecimal getStop()
  {
    return this.stop;
  }

  /**
   * Returns the step value of this.
   */
  public final BigDecimal getStep()
  {
    return this.step;
  }

  /**
   * Returns the number of data points that will be generated by this
   * function.
   */
  public final int calculatePoints()
  {
    int points = 0;
		
    switch (this.getScale())
    {
    case LIN_SCALE:
      // Linear with zero step size -> badness
      if (step.signum() == 0)
	return -1;

      points = stop
	.subtract(start)
	.divide(step, 0, BigDecimal.ROUND_FLOOR)
	.intValue()
	+ 1;
      break;
    case LOG10_SCALE:
      return logPoints(10.0);
    case LOG25_SCALE:
      return logPoints(25.0);
    case LOG50_SCALE:
      return logPoints(50.0);
    default:
      // should never get here
    }
    return points;
  }

  // helper function for calculatePoints
  private final int logPoints(double base)
  {
    // zero for start or stop values -> badness
    if (stop.signum() <= 0 || start.signum() <= 0)
      return -1;

    int points = 1 +
      (new BigDecimal
       (base * Math.log(Math.abs(stop.doubleValue() / start.doubleValue()))
	/ Math.log(10.0)))
      .setScale(TOLERANCE_SCALE, BigDecimal.ROUND_HALF_UP)
      .setScale(0, BigDecimal.ROUND_FLOOR)
      .intValue();
    return points;
  }

  // two VAR1Functions are equal if they have the same scale, equal
  // start values, equal stop values, and (only for LIN_SCALE) equal
  // step values.
  public final boolean equals(Object obj)
  {
    if (obj instanceof VAR1Function)
    {
      VAR1Function f = (VAR1Function) obj;

      return (this.scale == f.scale &&
	      this.start.compareTo(f.start) == 0 &&
	      this.stop.compareTo(f.stop) == 0 &&
	      (this.scale != LIN_SCALE ||
	       this.step.compareTo(f.step) == 0));
    }
    else
      return false;
  }

  /**
   * Accepts a Visitor, according to the Visitor design pattern.
   */
  public final void accept(Visitor v)
  {
    v.visitVAR1Function(this);
  }

} // end class VAR1Function