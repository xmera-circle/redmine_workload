class DateTools

 $holidays = ["2013-01-01","2013-01-02","2013-03-29","2013-04-01","2013-05-09","2013-05-20","2013-08-01","2013-09-16","2013-12-25"]
	
 #def init_holidays()
	#@holidays = ["2013-01-01","2013-03-29"]
	#@holidays[DateTime.new(2013,3,29).strftime("%Y-%m-%d")] = true
	#DateTime.new(2013,1,1),
	#DateTime.new(2013,1,2),
	#DateTime.new(2013,3,29),
	#DateTime.new(2013,4,1),
	#DateTime.new(2013,5,9),
	#DateTime.new(2013,5,20),
	#DateTime.new(2013,8,1),
	#DateTime.new(2013,9,16),
	#DateTime.new(2013,12,25)
 #end

  def distance_of_time_in_days(from_time, to_time = 0, inclusive = true)
    from_time = from_time.to_time if from_time.respond_to?(:to_time)
    if inclusive then
      from_time = from_time - 86400 
    end
    to_time = to_time.to_time if to_time.respond_to?(:to_time)
    distance_in_days = (((to_time.to_i - from_time.to_i).abs)/86400).round
    return (from_time > to_time ) ? "-#{distance_in_days}".to_i : distance_in_days
  end
  
  def stimated_days(  hours, days )
    return hours/days
  end

  def getRealDistanceInDays(inicio, fin )
    inicio = inicio.to_date
    fin = fin.to_date
    
    days = 0
    
    if inicio.to_time == fin.to_time then
	   return 1
    end

    while (inicio.to_time <= fin.to_time ) do
      if (inicio.cwday < 6 && !$holidays.include?(inicio.strftime("%Y-%m-%d") ))then
          days = days + 1
      end
      
      inicio = inicio.next  
    end
  return days  
end

  def add_commercial_days(fecha,days)
    fecha = fecha.to_date if fecha.respond_to?(:to_date)
    while days > 0
      fecha = fecha.next
      if (fecha.cwday < 6  !$holidays.include?(fecha.strftime("%Y-%m-%d") )) then
        days = days - 1
      end
      
    end
    
    return fecha.strftime("%Y-%m-%d")
    

  end
  
end
