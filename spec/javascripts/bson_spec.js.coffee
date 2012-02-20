describe "BSON to/from Extended JSON", ->
  #beforeEach ->

  describe "#toEJSON", ->
    it "ObjectId", ->
      id = new BSON.ObjectId('4f3feebb49f63b5b60000001')
      expect( id.toEJSON() ).toEqual {$oid: id.toString()}

    it "Date", ->
      date = new Date(42)
      expect( date.toEJSON() ).toEqual {$date: 42}

    it "RegExp", ->
      regexp = /foo/im
      expect( regexp.toEJSON() ).toEqual {$regex: 'foo', $options: 'im'}

    it "BSON.DBRef", ->
      ref = new BSON.DBRef('stuff', new BSON.ObjectId('4f3feebb49f63b5b60000002') )
      expect( ref.toEJSON() ).toEqual {$ns: ref.namespace, $id: ref.objectId.toString()}

    it "Array", ->
      array = [42, new Date(42), 689]
      expect( array.toEJSON() ).toEqual [array[0], array[1].toEJSON(), array[2]]

    it "Object", ->
      hash = { foo: { bar: { baaz: new Date(42) } } }
      expect( hash.toEJSON() ).toEqual { foo: { bar: { baaz: hash.foo.bar.baaz.toEJSON() } } }

  describe ".fromEJSON", ->
    it "Date", ->
      ejson = {$date: 42}
      expect( Date.fromEJSON(ejson) ).toEqual new Date(42)

    it "Regexp", ->
      ejson = {$regex: 'foo', $options: 'im'}
      expect( RegExp.fromEJSON(ejson) ).toEqual /foo/im

    it "ObjectId", ->
      ejson = {$oid: '4f3feebb49f63b5b60000001'}
      expect( BSON.ObjectId.fromEJSON(ejson) ).toEqual new BSON.ObjectId('4f3feebb49f63b5b60000001')

    it "BSON.DBRef", ->
      ejson = {$ns: 'stuff', $id: '4f3feebb49f63b5b60000002'}
      expect( BSON.DBRef.fromEJSON(ejson) ).toEqual new BSON.DBRef(ejson['$ns'], ejson['$id'])

    it "Array", ->
      ejson = [42, new Date(42).toEJSON(), 689]
      expect( Array.fromEJSON(ejson) ).toEqual [42, new Date(42), 689]

    it "Object", ->
      ejson = { foo: { bar: { baaz: new Date(42).toEJSON() } } }
      expect( Object.fromEJSON(ejson) ).toEqual { foo: { bar: { baaz: new Date(42) } } }
