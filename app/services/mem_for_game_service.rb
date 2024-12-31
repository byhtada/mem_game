class MemForGameService
  def self.call
    names = Mem.pluck(:name).sample(7)
    mem_names = []
    names.each do |m|
      mem_names.append({name: m, active: true})
    end
    JSON.dump(mem_names)
  end
end
