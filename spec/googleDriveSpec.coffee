### 
# (C) 2012 ICHIKAWA, Yuji (New 3 Rs)
###

describe 'googleDrive.File', ->
    describe 'checkAuth', ->
        it 'executes callback after success authorization', ->
            done = false
            googleDrive.checkAuth -> done = true
            waitsFor (-> done), 'never completed', 10000
            runs -> expect(done).toBe true
