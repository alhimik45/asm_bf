class String
  def is_digit?
      !!Float(self) rescue false
  end
end

class BFCompiler
# 0 | stack | 0 | 10 tmp cells| 0 | 3 cmp cell | 0 | ax | bx | cx | dx | 0 | 0 | 0 | 0 | 254 buffer | arrays... | strings... |
#       start pos ^                                               index of array ^   ^

    attr_accessor :registers
    
    def addRegister(name)
        @registers[name]=@regnow
        @regnow+=1
    end
    
    def initialize
        @program = ["<<<->>>"] #init stack
        @pos=0
        # registers offset
        @ro=16
        @eqR=@ro-4 # equal flag
        @ltR=@ro-3 # little flag
        @gtR=@ro-2 # great flag
        @regnow=@ro
        @registers={}
        addRegister "ax"
        addRegister "bx"
        addRegister "cx"
        addRegister "dx"
        #addRegister "sp"
        @indEl = @regnow+2 # index of array
        @arrays = []
        @total=256
    end
    
    def compileBf
        i=0
        @total = @total ==256? 0: @total
        "Min cells used:#{@total+@indEl}\n" + @program.join("").split(//).collect { |ch|
            i+=1
            if i>=80
              i=0
              ch+"\n"
            else
              ch
            end
          }.join("")
    end
    
    def gotoR(reg)
        @program << (reg-@pos>0? ">" : "<")*(reg-@pos).abs
        @pos=reg
    end
    
    def addNumToR(reg,num)
        gotoR(reg)
        @program << "+"*num
    end
    
    def subNumFromR(reg,num)
        gotoR(reg)
        @program << "-"*num
    end
    
    def moveRToR(reg1,reg2)
        startCycle(reg1)
          subNumFromR(reg1,1)
          addNumToR(reg2,1)
        endCycle(reg1)
    end
    
    def outR(reg)
        gotoR(reg)
        @program << "."
    end
    
    def inputR(reg)
        gotoR(reg)
        @program << ","
    end
    
    def startCycle(reg)
        gotoR(reg)
        @program << "["
    end
    
    def endCycle(reg)
        gotoR(reg)
        @program << "]"
    end
    
    def inc(reg)
        addNumToR(reg,1)
    end
    
    def dec(reg)
        subNumFromR(reg,1)
    end
    
    def zeroR(reg)
        startCycle(reg)
          dec reg
        endCycle(reg)
    end
    
    def setR(reg,num)
        zeroR(reg)
        addNumToR(reg,num)
    end
    
    def copyR(reg2,reg1)
        #copy reg1 to reg2
        zeroR(reg2)
        zeroR(0)
        startCycle(reg1)
          dec reg1
          inc reg2
          inc 0
        endCycle(reg1)
        moveRToR(0,reg1)
    end
    
    def addRToR(reg1,reg2)
      # reg1=reg1+reg2
        zeroR(0)
        startCycle(reg2)
          dec reg2
          inc reg1
          inc 0
        endCycle(reg2)
        moveRToR(0,reg2)
    end
    
    def subRFromR(reg1,reg2)
      # reg1= reg1-reg2
        zeroR(0)
        startCycle(reg2)
          dec reg2
          dec reg1
          inc 0
        endCycle(reg2)
        moveRToR(0,reg2)
    end
    
    def pushNumToStack(num)
        setR(0,num)
        @program << "-<<[<]<[->+<]<<[-]>+>>[>]>[-<<[<]<+>>[>]>]"
    end
    
    def pushRToStack(reg)
        copyR(1,reg)
        moveRToR(1,0)
        gotoR(0)
        @program << "-<<[<]<[->+<]<<[-]>+>>[>]>[-<<[<]<+>>[>]>]"
    end
    
    def popNumToR(reg)
        zeroR(0)
        @program << "+<<[<]<-[->>[>]>+<<[<]<]>>[-<+>]>[>]>"
        zeroR(reg)
        moveRToR(0,reg)
    end
    
    def mulRonR(reg1,reg2)
        zeroR(0)
        zeroR(1)
        startCycle(reg1)
          inc 1
          dec reg1
        endCycle(reg1)
        startCycle(1)
          startCycle(reg2)
            inc reg1
            inc 0
            dec reg2
          endCycle(reg2)
          startCycle(0)
            inc reg2
            dec 0
          endCycle(0)
          dec 1
        endCycle(1)
    end
    
    def divRonR(reg1,reg2)
          zeroR(0)
          zeroR(1)
          zeroR(2)
          zeroR(3)
          zeroR(4)
          copyR(1,reg1)
          copyR(2,reg2)
          # divmod algorithm
          gotoR(1)
          @program << "[->-[>+>>]>[+[-<+>]>+>>]<<<<<]"
          copyR(reg2,3)
          copyR(reg1,4)
    end
    
    def cmpRR(reg1,reg2)
        copyR(1,reg1)
        copyR(2,reg2)
        zeroR(0)
        setR(@eqR,1)
        setR(@ltR,1)
        setR(@gtR,2)
        startCycle(2)
          subNumFromR(2,1)
          startCycle(1)
            inc @ltR
            moveRToR(1,0)
          endCycle(1)
          moveRToR(0,1)
          dec @ltR
          dec 1
        endCycle(2)
        startCycle(1)
          inc @eqR
          zeroR(1)
        endCycle(1)
        dec @eqR
        startCycle(@ltR)
          dec @gtR
          moveRToR(@ltR,0)
        endCycle(@ltR)
        moveRToR(0,@ltR)
        startCycle(@eqR)
          dec @gtR
          moveRToR(@eqR,0)
        endCycle(@eqR)
        moveRToR(0,@eqR)
    end
    
    def declareArray(name,size)
        @arrays << {:name => name , :size => size+1 }
        @total+=size+1
    end
    
    def getKnownArrElem(name,index,reg)
        # set reg to name[index]
        toArr=256
        i=0
        while @arrays[i][:name]!=name
            toArr+=@arrays[i][:size]
            i+=1
        end
        toArr+=index
        copyR(reg,@indEl+toArr)
    end
    
    def getUnknownArrElem(name,regindex,reg)
        # set reg to name[regindex]
        toArr=256
        i=0
        while @arrays[i][:name]!=name
            toArr+=@arrays[i][:size]
            i+=1
        end
        copyR(@indEl,regindex)
        copyR(@indEl+1,regindex)
        gotoR(@indEl)
        # copy indEl and indEl+1 on regindex register forward 
        @program << "[>[->+<]<[->+<]>-]" 
        # go to arr element
        @program << ">"*toArr
        # copy arr element
        @program << "[-" << "<"*toArr <<"+<+>" << ">"*toArr << "]"
        # restore arr element
        @program << "<"*toArr << "<[->" << ">"*toArr << "+" << "<"*toArr << "<]"
        # copy indEl and indEl+1 back
        @program << ">>[<[-<+>]>[-<+>]<-]<"
        # fast move
        @pos = @indEl
        startCycle(@indEl)
            dec @indEl
            inc reg
        endCycle(@indEl)
    end
    
    def setKnownArrElemWithR(name,index,reg)
        # set name[index] to reg
        toArr=256
        i=0
        while @arrays[i][:name]!=name
            toArr+=@arrays[i][:size]
            i+=1
        end
        toArr+=index
        copyR(@indEl+toArr,reg)
    end
    
    def setKnownArrElemWithNum(name,index,num)
        # set name[index] to num
        toArr=256
        i=0
        while @arrays[i][:name]!=name
            toArr+=@arrays[i][:size]
            i+=1
        end
        toArr+=index
        setR(@indEl+toArr,num)
    end
    
    def setUnknownArrElemWithNum(name,regindex,num)
      # set name[regindex] to num
        toArr=256
        i=0
        while @arrays[i][:name]!=name
            toArr+=@arrays[i][:size]
            i+=1
        end
        setR(@indEl-1,num)
        copyR(@indEl,regindex)
        copyR(@indEl+1,regindex)
        gotoR(@indEl) 
        @program <<  "[>[->+<]<[->+<]<[->+<]>>-]"
        @program << ">"*toArr
        @program << "[-]"
        @program << "<"*toArr
        @program << "<[->"
        @program << ">"*toArr
        @program << "+"
        @program << "<"*toArr
        @program << "<]>>[[-<+>]<-]<"
        @pos=@indEl
    end
    
    def setUnknownArrElemWithR(name,regindex,reg)
      # set name[regindex] to reg
        toArr=256
        i=0
        while @arrays[i][:name]!=name
            toArr+=@arrays[i][:size]
            i+=1
        end
        copyR(@indEl-1,reg)
        copyR(@indEl,regindex)
        copyR(@indEl+1,regindex)
        gotoR(@indEl) 
        @program <<  "[>[->+<]<[->+<]<[->+<]>>-]"
        @program << ">"*toArr
        @program << "[-]"
        @program << "<"*toArr
        @program << "<[->"
        @program << ">"*toArr
        @program << "+"
        @program << "<"*toArr
        @program << "<]>>[[-<+>]<-]<"
        @pos=@indEl
    end
    
    def makeInitCode(numArr)
        res=[]
        numArr.each { |num|
          res << "+"*num << ">"
        }
        res.join("")
    end
    
    def addString(name, data)
        declareArray(name,data.length)
        forInit=data.split("").collect { |ch| ch.ord }
        toArr=256
        i=0
        while @arrays[i][:name]!=name
            toArr+=@arrays[i][:size]
            i+=1
        end
        @program.unshift(">"*(toArr+@indEl)+makeInitCode(forInit)+"<"*(toArr+@indEl+data.length))      
    end
    
    def putStr(name)
        toArr=256
        i=0
        while @arrays[i][:name]!=name
            toArr+=@arrays[i][:size]
            i+=1
        end
        gotoR(@indEl)
        @program << ">"*toArr << "[.>]<[<]>" << "<"*toArr
    end
    
    def ifFalse(op)
        case op
        when :eq
          reg=@eqR
        when :lt
          reg=@ltR
        when :gt
          reg=@gtR
        else
          raise "logic error"
        end
        zeroR(5)
        zeroR(6)
        startCycle(reg)
          inc 5
          moveRToR(reg,6)
        endCycle(reg)
        moveRToR(6,reg)
        startCycle(5)
    end
    
    def ifTrue(op)
        case op
        when :eq
          reg=@eqR
        when :lt
          reg=@ltR
        when :gt
          reg=@gtR
        else
          raise "logic error"
        end
        zeroR(5)
        zeroR(6)
        startCycle(reg)
          dec 5
          moveRToR(reg,6)
        endCycle(reg)
        moveRToR(6,reg)
        inc 5
        startCycle(5)
    end
    
    def endif
      zeroR(5)
      endCycle(5)
    end
    
end
i=0
tmp=[]

word=[]
instring=false

STDIN.read.split("").each { |a|
  if !instring
    if a==" " or a=="\n"
      tmp << word.join("").chomp if word.size >0
      word=[]
    else
      word << a
    end
    if a=="\""
      instring=true
      word=[]
    end
  else
    if a=="\""
       tmp << word.join("").chomp
       word=[]
       instring=false
    else
      word << a
    end
  end
}
tmp << word.join("").chomp
#puts tmp.inspect
cycles = []
a=BFCompiler.new
registers=a.registers
while i<tmp.length
    case tmp[i].upcase
    when "MOV"
        if registers.has_key?(tmp[i+2])
            a.copyR(registers[tmp[i+1]],registers[tmp[i+2]])
        else
            a.setR(registers[tmp[i+1]], tmp[i+2].is_digit? ?  tmp[i+2].to_i: tmp[i+2].ord)
        end
        i+=3  
    when "SUB"
        if registers.has_key?(tmp[i+2])
            a.subRFromR(registers[tmp[i+1]],registers[tmp[i+2]])
        else
            a.subNumFromR(registers[tmp[i+1]],tmp[i+2].to_i)
        end
        i+=3
    when "ADD"
        if registers.has_key?(tmp[i+2])
            a.addRToR(registers[tmp[i+1]],registers[tmp[i+2]])
        else
            a.addNumToR(registers[tmp[i+1]],tmp[i+2].to_i)
        end
        i+=3
    when "MUL"
        a.mulRonR(registers[tmp[i+1]],registers[tmp[i+2]])
        i+=3
    when "DIV"
        a.divRonR(registers[tmp[i+1]],registers[tmp[i+2]])
        i+=3
    when "ARRAY"
        a.declareArray(tmp[i+1],tmp[i+2].to_i)
        i+=3
    when "CMP"
        a.cmpRR(registers[tmp[i+1]],registers[tmp[i+2]])
        i+=3
    when "GET"
        if registers.has_key?(tmp[i+2])
            a.getUnknownArrElem(tmp[i+1],registers[tmp[i+2]],registers[tmp[i+3]])
        else
            a.getKnownArrElem(tmp[i+1],tmp[i+2].to_i,registers[tmp[i+3]])
        end
        i+=4
    when "SET"
        if registers.has_key?(tmp[i+2])
            if registers.has_key?(tmp[i+3])
                a.setUnknownArrElemWithR(tmp[i+1],registers[tmp[i+2]],registers[tmp[i+3]])
            else
                a.setUnknownArrElemWithNum(tmp[i+1],registers[tmp[i+2]],tmp[i+3].to_i)
            end
        else
            if registers.has_key?(tmp[i+3])
                a.setKnownArrElemWithR(tmp[i+1],tmp[i+2].to_i,registers[tmp[i+3]])
            else
                a.setKnownArrElemWithNum(tmp[i+1],tmp[i+2].to_i,tmp[i+3].to_i)
            end
        end
        i+=4
    when "PUSH"
        if registers.has_key?(tmp[i+1])
            a.pushRToStack(registers[tmp[i+1]])
        else
            a.pushNumToStack(tmp[i+1].to_i)
        end
        i+=2
        
    when "NE"
        a.ifFalse(:eq)
        i+=1
    when "NL"
        a.ifFalse(:lt)
        i+=1
    when "NG"
        a.ifFalse(:gt)
        i+=1
    when "EQ"
        a.ifTrue(:eq)
        i+=1
    when "LT"
        a.ifTrue(:lt)
        i+=1
    when "GT"
        a.ifTrue(:gt)
        i+=1
    when "PUT"
        a.outR(registers[tmp[i+1]])
        i+=2
    when "POP"
        a.popNumToR(registers[tmp[i+1]])
        i+=2    
    when "TAKE"
        a.inputR(registers[tmp[i+1]])
        i+=2
    when "PUTS"
        a.putStr(tmp[i+1])
        i+=2
    when "INC"
        a.inc(registers[tmp[i+1]])
        i+=2
    when "DEC"
        a.dec(registers[tmp[i+1]])
        i+=2
    when "WHILE"
        a.startCycle(registers[tmp[i+1]])
        cycles << registers[tmp[i+1]]
        i+=2
    when "ENDWHILE"
        a.endCycle(cycles.pop)
        i+=1
    when "END"
        a.endif
        i+=1
    when "STRING"
        a.addString(tmp[i+1],tmp[i+2])
        i+=3
    else
        i+=1
    end
end
puts a.compileBf