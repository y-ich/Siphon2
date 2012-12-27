### 
# (C) 2012 ICHIKAWA, Yuji (New 3 Rs)
###

describe 'getDeclaredVariable', ->
    it 'returns a declared variable from JS source', ->
        expect(getDeclaredVariables('var a;')).toEqual ['a']
    it 'returns a declared variable without ;', ->
        expect(getDeclaredVariables('var a')).toEqual ['a']
    it 'returns declared variables with comma', ->
        expect(getDeclaredVariables('var a,b;')).toEqual ['a', 'b']
    it 'returns declared variables with comma and space', ->
        expect(getDeclaredVariables('var a, b;')).toEqual ['a', 'b']
    it 'returns declared variables for plural lines', ->
        expect(getDeclaredVariables('var a,\n b;')).toEqual ['a', 'b']
    it 'returns a declared variables for for loop', ->
        expect(getDeclaredVariables('for (var a = 0; a < length; a++)')).toEqual ['a']
    it 'returns declared variables for multi declarations', ->
        expect(getDeclaredVariables('var a;\nvar b;')).toEqual ['a', 'b']
