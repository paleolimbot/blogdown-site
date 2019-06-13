---
title: 'Dynamic Forms & Formsets in Django'
author: Dewey Dunnington
date: '2017-08-06'
slug: []
categories: []
tags: ["Django", "Python", "Tutorials"]
subtitle: ''
summary: ''
authors: []
lastmod: '2017-08-06T17:17:02+00:00'
featured: no
image:
  caption: ''
  focal_point: ''
  preview_only: no
projects: []
---

In working on a <a href="https://www.djangoproject.com/">Django</a> web app recently, I ran across the problem of creating programatically-created forms. Creating regular forms in Django is a <a href="https://docs.djangoproject.com/en/1.11/topics/forms/#building-a-form-in-django">piece of cake</a>:


```python
from django import forms
class NameForm(forms.Form):
    your_name = forms.CharField(label='Your name', max_length=100)
```

Creating many forms is [equally easy](https://docs.djangoproject.com/en/1.11/topics/forms/formsets/), once the initial form class has been defined:

```python
from django.forms import formset_factory
NameFormSet = formset_factory(NameForm)
```

The ease of Django is magical, but what if the form fields need to be programmatically assigned? In my case, I'd like to provide a data entry template (user created) that leverages Django's powerful form and field libraries, but because form fields are assigned at the class level, they [cannot be assigned dynamically](https://stackoverflow.com/questions/68645/static-class-variables-in-python).

Luckily, form fields can be changed after a `Form` has been instantiated (see [this example](https://jacobian.org/writing/dynamic-form-generation/) from Jacob Kaplan-Moss), such that one only needs to modify the constructor of the custom `Form` class to make a dynamically-generated form class:

```python
class DataViewForm(forms.Form):
    def __init__(self, data_view, *args, **kwargs):
        super(DataViewForm, self).__init__(*args, **kwargs)
        # here data_view is the object that contains custom form information
        for item in data_view.column_spec:
            self.fields[item] = data_view.fields[item]
```

Formset objects are a little trickier, because they are created by the `formset_factory()` function, which takes the form class as its first argument and returning a `type` object that is used in a similar way as a `Form`. Upon inspecting the [source code of the formeset module](https://docs.djangoproject.com/en/1.11/_modules/django/forms/formsets/), it appears that the original `Form` class is used only as a callable to instantiate `Form` objects. This means that we can pass any callable that returns a `Form` instance to `formset_factory()`, not limited to `type` objects.

```python
# define a function that returns a callable that generates a proper form based on a
# data_view object
def form_class_factory(data_view):
    def new_form(*args, **kwargs):
        return DataViewForm(data_view, *args, **kwargs)
    return new_form

# pass the function returned from form_class_factory to formset_factory() 
# as a stand-in for a Form class
custom_form_class = form_class_factory(data_view_instance)
DataViewInstanceFormset = formset_factory(custom_form_class)
```

I'm not an expert in Django or web development, but it seems that the above solution works reasonably well to create forms when the format for the form must be passed programmatically.


